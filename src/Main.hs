{-# LANGUAGE OverloadedStrings #-}

-- SPDX-License-Identifier: BSD-3-Clause

import qualified Data.ByteString as B
import qualified Data.Text.Encoding as TE
import qualified Data.Text.IO as T
import SimpleCmdArgs

import qualified GI.Pango as Pango
-- import qualified GI.Pango.Objects.Context as PangoContext
-- import qualified GI.Pango.Objects.Font as PangoFont
-- import qualified GI.Pango.Structs.Analysis as PangoAnalysis
import qualified GI.Pango.Structs.AttrList as PangoAttrList
-- import qualified GI.Pango.Structs.FontDescription as PangoFontDesc
-- import qualified GI.Pango.Structs.Item as PangoItem

import qualified GI.PangoCairo.Interfaces.FontMap as PangoCairo

import qualified Data.Text as T

main :: IO ()
main = do
  simpleCmdArgs Nothing "fontwhich"
    "Describes the fonts used to render text with pango" $
    run
    <$> optional (strOptionWith 'f' "font" "FONT" "Base font [default: Sans]")
    <*> many (strArg "TEXT")

run :: Maybe String -> [String] -> IO ()
run mfont txt = do
  -- 1. Get a default Font Map and Context
  fontMap <- PangoCairo.fontMapGetDefault
  context <- Pango.fontMapCreateContext fontMap

  let myText =
        T.pack $
        if null txt then "Hello 🌍 World 世界"
        else unwords txt
  T.putStrLn myText
  baseFontDesc <- Pango.fontDescriptionFromString (maybe "Sans" T.pack mfont)
  Pango.contextSetFontDescription context $ Just baseFontDesc

  atr <- PangoAttrList.attrListNew
  -- 3. Itemize the text
  -- Arguments: context, text, start_index, length, attributes, cached_iter
  -- Note: Length is in bytes, but gi-pango handles some conversion.
  -- For simplicity, we use -1 for "until end of string".

  let utf8Bytes = TE.encodeUtf8 myText
  print $ B.length utf8Bytes

  items <- Pango.itemize context myText 0 (fromIntegral $ B.length utf8Bytes) atr Nothing

  -- when (null args) $
  --   putStrLn $ "Analyzing: " ++ T.unpack myText

  -- 4. Process the list of Pango.Item
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

      putStrLn $ T.unpack itemText ++ ": "
        ++ maybe "Unknown" T.unpack family
