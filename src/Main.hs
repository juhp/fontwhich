-- SPDX-License-Identifier: BSD-3-Clause

import Control.Monad.Extra (whenJust)
import qualified Data.ByteString as B
import Data.Maybe (fromMaybe)
import qualified Data.Text as T
import qualified Data.Text.Encoding as TE
import SimpleCmd (error', (+-+))
import SimpleCmdArgs
import System.Environment (getArgs, withArgs)

import qualified GI.Pango as Pango
import qualified GI.PangoCairo.Interfaces.FontMap as PangoCairo

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
    <*> many (strArg "TEXT")

run :: Maybe String -> Maybe String -> [String] -> IO ()
run mfont mlang txt = do
  -- Get a default Font Map and Context
  fontMap <- PangoCairo.fontMapGetDefault
  context <- Pango.fontMapCreateContext fontMap
  attr <- Pango.attrListNew
  baseFont <- Pango.fontDescriptionFromString $ T.pack $ fromMaybe "Sans" mfont
  mplang <- Pango.languageFromString $ T.pack <$> mlang

  if null txt then do
      case mplang of
        Nothing -> error' "no language determined"
        Just plang -> do
          maybeFontset <- Pango.fontMapLoadFontset fontMap context baseFont plang
          case maybeFontset of
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
                  putStrLn $ "Primary font" +-+ maybe "" ("for" +-+) mlang +-+ "is:" +-+ show family
                return True -- stop after first font
    else do
      let myText = T.pack $ unwords txt

      Pango.contextSetFontDescription context $ Just baseFont
      Pango.contextSetLanguage context mplang

      let utf8Bytes = TE.encodeUtf8 myText
      putStrLn $ show (B.length utf8Bytes) +-+ "bytes"

      -- start_index, length, cached_iter
      items <- Pango.itemize context myText 0 (fromIntegral $ B.length utf8Bytes) attr Nothing
      mapM_ (printItemInfo utf8Bytes) items

printItemInfo :: B.ByteString -> Pango.Item -> IO ()
printItemInfo utf8Bytes item = do
  -- Get the Analysis struct from the Item
  analysis <- Pango.getItemAnalysis item

  -- Extract the Font used for this specific item
  maybeFont <- Pango.getAnalysisFont analysis

  case maybeFont of
    Nothing -> putStrLn "No font assigned to this segment."
    Just font -> do
      desc <- Pango.fontDescribe font
      family <- Pango.fontDescriptionGetFamily desc

      -- Offsets in Pango are byte offsets
      offset <- Pango.getItemOffset item
      len <- Pango.getItemLength item
      let itemBytes = B.take (fromIntegral len) $ B.drop (fromIntegral offset) utf8Bytes
          itemText  = TE.decodeUtf8 itemBytes
      putStrLn $
        '\'' : (T.unpack itemText) ++ "'" +-+ ":" +-+ maybe "Unknown" T.unpack family
