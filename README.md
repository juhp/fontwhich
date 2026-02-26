# whichfont

`$ fontwhich --help`

```
fontwhich

Usage: fontwhich [--version] [-f|--font FONT] [-l|--lang LANG] [TEXT]

  Describes the fonts used to render text with pango

Available options:
  -h,--help                Show this help text
  --version                Show version
  -f,--font FONT           Base font [default: Sans]
  -l,--lang LANG           Language code
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

(Note some of the results are "unexpected" because of my environment)
