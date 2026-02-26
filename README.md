# whichfont

`$ fontwhich --help`

```
fontwhich

Usage: fontwhich [--version] [-f|--font FONT] [TEXT]

  Describes the fonts used to render text with pango

Available options:
  -h,--help                Show this help text
  --version                Show version
  -f,--font FONT           Base font [default: Sans]
```

`$ fontwhich`

```
Hello 🌍 World 世界
23
Hello : Noto Sans
🌍: Noto Color Emoji
 World : Noto Sans
世界: Droid Sans Fallback
```

`$ fontwhich -f Serif "こんにちは 😀 世界"`

```
こんにちは 😀 世界
27
こんにちは : Noto Sans CJK JP
😀: Noto Color Emoji
 : Noto Serif
世界: Noto Sans CJK JP
```
