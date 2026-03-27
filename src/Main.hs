-- SPDX-License-Identifier: BSD-3-Clause

import Control.Monad.Extra (filterM, forM_, unless, when, whenJust)
import qualified Data.ByteString as B
import Data.Char (ord)
import Data.Maybe (fromMaybe, isNothing)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import qualified GI.Pango as Pango
import qualified GI.PangoCairo.Interfaces.FontMap as PangoCairo
import SimpleCmd (error', (+-+))
import SimpleCmdArgs hiding (str)
import System.Environment (getArgs, withArgs)
import Text.Printf (printf)
import qualified Unicode.Char.General.Names as UN
import qualified Unicode.Char.General.Scripts as US

import Paths_fontwhich (version)

main :: IO ()
main = do
  args <- getArgs
  if null args
    then withArgs ["--help"] main'
    else main'

main' :: IO ()
main' =
  simpleCmdArgs (Just version) "fontwhich"
  "Describes the fonts used to render text with pango" $
    run
    <$> optional (strOptionWith 'f' "font" "FONT" "Base font [default: Sans]")
    <*> optional (strOptionWith 'l' "lang" "LANG" "Language code")
    <*> switchWith 'b' "utf8" "Output UTF-8 hex codes"
    <*> switchWith 'u' "unicode" "Output Unicode data"
    <*> many (strArg "TEXT")

run :: Maybe String -> Maybe String -> Bool -> Bool -> [String] -> IO ()
run mfont mlang hex unicode txt = do
  -- Get a default Font Map and Context
  fontMap <- PangoCairo.fontMapGetDefault
  context <- Pango.fontMapCreateContext fontMap
  let baseName = fromMaybe "Sans" mfont
  baseFont <- Pango.fontDescriptionFromString $ T.pack baseName
  mplang <- Pango.languageFromString $ T.pack <$> mlang

  if null txt then do
      case mplang of
        Nothing -> error' "no language determined or text given"
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
                whenJust mfamily $ \family ->
                  putStrLn $ "Primary" +-+ baseName +-+ "font" +-+ maybe "" ("for" +-+) mlang +-+ "is:" +-+ show family
                return True -- stop after first font
    else do
      let myText = T.pack $ unwords txt

      Pango.contextSetFontDescription context $ Just baseFont
      Pango.contextSetLanguage context mplang

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

quoteStr :: String -> String
quoteStr str = '\'' : str ++ "'"

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
    putStrLn $ " <" ++ codepoint ++ ">:" +-+ fromMaybe "unknown codepoint" mname +-+ '[' : show script ++ "]" -- +-+ '(' : US.scriptShortName script ++ ")"
  where
    hexify :: Char -> String
    hexify char =
      let bytes = TE.encodeUtf8 $ T.singleton char
      in '[' : unwords [printf "%02x" b | b <- B.unpack bytes] ++ "]"
