-- SPDX-License-Identifier: BSD-3-Clause

import Control.Monad.Extra (filterM, forM_, unless, when, whenJust)
import qualified Data.ByteString as B
import Data.Char (ord)
import Data.List (singleton)
import Data.Maybe (fromMaybe, isNothing)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified GI.Pango as Pango
import qualified GI.PangoCairo.Interfaces.FontMap as PangoCairo
import SimpleCmd (error', (+-+))
import SimpleCmdArgs (flagWith', optional, simpleCmdArgs, some, strArg,
                      strOptionWith, switchWith, (<|>))
import Text.Printf (printf)
import qualified Unicode.Char.General.Names as UN
import qualified Unicode.Char.General.Scripts as US

import Paths_fontwhich (version)

data LangText = SampleText -- | LangName

data TextReq =
  LangReq !String !(Maybe LangText) | InputText ![String]

main :: IO ()
main =
  simpleCmdArgs (Just version) "fontwhich"
  "Describes the fonts used to render text with pango" $
    run
    <$> optional (strOptionWith 'f' "font" "FONT" "Base font [default: Sans]")
    <*> switchWith 'b' "utf8" "Output UTF-8 hex codes"
    <*> switchWith 'u' "unicode" "Output Unicode data"
    <*> textReqOpt
  where
    textReqOpt =
      (LangReq
       <$> strOptionWith 'l' "lang" "LANG" "Language code"
       <*> optional (flagWith' SampleText 's' "sample-text" "Use Pango sample text for language"
                     -- <|> flagWith' LangName 'n' "lang-name" "Use language name as text"
                    )
      )
      <|>
      InputText <$> some (strArg "TEXT")

run :: Maybe String -> Bool -> Bool -> TextReq -> IO ()
run mfont hex unicode txtreq = do
  -- Get a default Font Map and Context
  fontMap <- PangoCairo.fontMapGetDefault
  context <- Pango.fontMapCreateContext fontMap
  let baseName = fromMaybe "Sans" mfont
  baseFont <- Pango.fontDescriptionFromString $ T.pack baseName
  (txt,mlang) <-
    case txtreq of
      InputText args -> return (args,Nothing)
      LangReq lang mltxt -> do
        mplang <- Pango.languageFromString $ Just $ T.pack lang
        t <-
          case mltxt of
            Nothing -> return []
            Just SampleText ->
              words . T.unpack <$> Pango.languageGetSampleString mplang
            -- FIXME with iso-codes json + gettext perhaps
            -- Just LangName -> return ["To be implemented!"]
        return (t,mplang)

  if null txt then do
      case mlang of
        Nothing -> error' "no language or text string specified"
        Just plang -> do
          mfontset <- Pango.fontMapLoadFontset fontMap context baseFont plang
          case mfontset of
            Nothing -> error' "no fontset found"
            Just fs -> do
              -- Get the first (primary) font in the fontset
              -- 'fontsetForeach' is the standard way to inspect them
              -- For a quick check, we can just look at the primary result
              -- In many cases, we want to see the first font that Pango resolves
              Pango.fontsetForeach fs $ \_ font -> do
                desc' <- Pango.fontDescribe font
                mfamily <- Pango.fontDescriptionGetFamily desc'
                whenJust mfamily $ \family -> do
                  mlangs <- Pango.fontGetLanguages font
                  let missing =
                        case mlangs of
                          Nothing -> ""
                          Just langs ->
                            if plang `elem` langs
                            then ""
                            else parenStr "missing coverage"
                  -- was: +-+ maybe "" (("for" +-+) . quoteStr)  mlang
                  putStrLn $ "Primary" +-+ baseName +-+ "font" +-+ "is:" +-+ show family +-+ missing
                return True -- stop after first font
    else do
      let myText = T.pack $ unwords txt

      Pango.contextSetFontDescription context $ Just baseFont
      Pango.contextSetLanguage context mlang

      let utf8Bytes = TE.encodeUtf8 myText
      when (hex || unicode) $
        putStr $ show (B.length utf8Bytes) +-+ "bytes;"

      attr <- Pango.attrListNew
      -- start_index, length, cached_iter
      items <- Pango.itemize context myText 0 (fromIntegral $ B.length utf8Bytes) attr Nothing
      when (hex || unicode) $
        putStrLn $
        if length items > 1
        then ' ' : show (length items) +-+ "pango items"
        else ""
      mapM (itemString utf8Bytes) items >>=
        mapM_ (printItemInfo hex unicode)
  where
    itemString :: B.ByteString -> Pango.Item -> IO (String, Pango.Item)
    itemString utf8Bytes item = do
      -- Offsets in Pango are bytes
      offset <- Pango.getItemOffset item
      len <- Pango.getItemLength item
      let itemBytes = B.take (fromIntegral len) $ B.drop (fromIntegral offset) utf8Bytes
      return (T.unpack $ TE.decodeUtf8 itemBytes, item)

surround :: Char -> Char -> String -> String
surround o c s =
  o : s ++ singleton c

quoteStr :: String -> String
quoteStr = surround '\'' '\''

parenStr :: String -> String
parenStr = surround '(' ')'

printItemInfo :: Bool -> Bool -> (String, Pango.Item) -> IO ()
printItemInfo hex unicode (str,item) = do
  -- Get the Analysis struct from the Item
  analysis <- Pango.getItemAnalysis item

  -- Extract the Font used for this specific item
  maybeFont <- Pango.getAnalysisFont analysis

  mfamily <-
    case maybeFont of
      Nothing -> do
        putStrLn "No fonts installed?"
        return Nothing
      Just font -> do
        notcovered <- filterM (fmap not . Pango.fontHasChar font) str
        unless (null notcovered) $
          putStrLn $ "no font coverage for" +-+ quoteStr notcovered ++ "!"
        if notcovered == str
          then return Nothing
          else Pango.fontDescribe font >>= Pango.fontDescriptionGetFamily

  let hexStr =
        if hex
        then unwords $ map hexify str
        else ""
  case mfamily of
    Just family ->
      putStrLn $ quoteStr str +-+ hexStr +-+ ":" +-+ T.unpack family
    Nothing ->
      unless (null hexStr) $
      putStrLn $ quoteStr str +-+ hexStr

  when (unicode || isNothing mfamily) $
    forM_ str $ \char -> do
    putChar char
    let mname = UN.name char
        script = US.script char
        codepoint = printf "U+%04X" (ord char)
    putStrLn $ " <" ++ codepoint ++ ">:" +-+ fromMaybe "unknown codepoint" mname +-+ '[' : show script ++ "]" -- +-+ parenStr (US.scriptShortName script)
  where
    hexify :: Char -> String
    hexify char =
      let bytes = TE.encodeUtf8 $ T.singleton char
      in '[' : unwords [printf "%02x" b | b <- B.unpack bytes] ++ "]"
