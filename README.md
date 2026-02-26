# whichfont

`$ fontwhich --help`

```
fontwhich

Usage: fontwhich [--version] [-f|--font FONT] [-l|--lang LANG] [-x|--hex] [TEXT]

  Describes the fonts used to render text with pango

Available options:
  -h,--help                Show this help text
  --version                Show version
  -f,--font FONT           Base font [default: Sans]
  -l,--lang LANG           Language code
  -x,--hex                 Output UTF-8 hex codes
```

`$ fontwhich Hello 🌍 World 世界`

```
23 bytes
'Hello ' : Noto Sans
'🌍' : Noto Color Emoji
' World ' : Noto Sans
'世界' : Droid Sans Fallback
```

`$ fontwhich -f Serif "こんにちは 😀 世界"`

```
27 bytes
'こんにちは ' : Noto Sans CJK JP
'😀' : Noto Color Emoji
' ' : Noto Serif
'世界' : Noto Sans CJK JP
```

`$ fontwhich -l ja`

```
Primary font for ja is: "Droid Sans Fallback"
```

`$ fontwhich --hex 🍊`

```
4 bytes
'🍊' [f0 9f 8d 8a] : Noto Color Emoji
```


(Note some of the results are "unexpected" because of my environment)
