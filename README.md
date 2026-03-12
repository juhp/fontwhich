# Fontwhich

Fontwhich is a small CLI tool that uses pango to show
which default fonts are used to render some text.

It should work on any Linux distro with the Cairo and Pango libraries:
it requires the fonts to be available but not a graphical session.

## Usage

`$ fontwhich --version`

```
0.1.1
```

`$ fontwhich --help`

```
fontwhich

Usage: fontwhich [--version] [-f|--font FONT] [-l|--lang LANG] [-x|--hex] 
                 [-u|--unicode] [TEXT]

  Describes the fonts used to render text with pango

Available options:
  -h,--help                Show this help text
  --version                Show version
  -f,--font FONT           Base font [default: Sans]
  -l,--lang LANG           Language code
  -x,--hex                 Output UTF-8 hex codes
  -u,--unicode             Output Unicode data
```

`$ fontwhich Hello 🌍 World 世界`

```
23 bytes; 4 items
'Hello ' : Noto Sans
'🌍' : Noto Color Emoji
' World ' : Noto Sans
'世界' : Noto Sans CJK JP
```

`$ fontwhich -f Serif "こんにちは 😀 世界"`

```
'こんにちは ' : Noto Serif CJK JP
27 bytes; 4 items
'😀' : Noto Color Emoji
' ' : Noto Serif CJK JP
'世界' : Noto Serif CJK JP
```

`$ fontwhich -l ja`

```
Primary font for ja is: "Noto Sans CJK JP"
```

`$ fontwhich --hex 🍊`

```
4 bytes; 1 item
'🍊' [f0 9f 8d 8a] : Noto Color Emoji
```

## Building and installation
On Fedora:
```
$ cabal-rpm builddep
$ cabal install
```

There is a copr repo: <https://copr.fedorainfracloud.org/coprs/petersen/fontwhich/>

## Misc
Code was assisted with Gemini Pro 3.1.

The tool is related conceptually to <https://github.com/sudipshil9862/whichfont> (C codebase).

## Collaborate

The code is distributed under GPLv3+.

Repository: <https://github.com/juhp/fontwhich>
