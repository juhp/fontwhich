# fontwhich releases

## 0.3 (2026-03-27)
- improve no coverage logic
- when no font output --unicode data
- for --language check that primary font has coverage
- check normalized lang is in fontconfig orth list
- new pango --sample-text option with --language
- add --list-langs option to list all fc orths
- add --all-langs which iterates over all orth langs

## 0.2.1 (2026-03-26)
- check and warn about characters without font coverage
- output base font name when no text given

## 0.2 (2026-03-12)
- add --unicode for unicode data output (uses `unicode-data`)
- rename --hex to --utf8 (for hex bytes)
- show number of pango items with --utf8 or --unicode
- only print number of bytes with --utf8 or --unicode

## 0.1.0 (2026-02-27)
- initial release with --font --lang and --hex
