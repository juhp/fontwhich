# Fontwhich

Fontwhich is a small CLI tool that uses pango to show
which default fonts are used to render some text.

It should work on any Linux distro with the Cairo and Pango libraries:
it requires the fonts to be available but not a graphical session.

## Usage

`$ fontwhich --version`

```
0.3
```

`$ fontwhich --help`

```
fontwhich

Usage: fontwhich [--version] [-f|--font FONT] [-b|--utf8] [-u|--unicode] 
                 (--list-langs | (-l|--lang LANG) [-s|--sample-text] | TEXT)

  Describes the fonts used to render text with pango

Available options:
  -h,--help                Show this help text
  --version                Show version
  -f,--font FONT           Base font [default: Sans]
  -b,--utf8                Output UTF-8 hex codes
  -u,--unicode             Output Unicode data
  --list-langs             List language orthography
  -l,--lang LANG           Language code
  -s,--sample-text         Use Pango sample text for language
```

`$ fontwhich Hello 🌍 World 世界`

```
'Hello ' : Noto Sans
'🌍' : Noto Color Emoji
' World ' : Noto Sans
'世界' : Noto Sans CJK JP
```

`$ fontwhich -f Serif "こんにちは 😀 世界"`

```
'こんにちは ' : Noto Serif CJK JP
'😀' : Noto Color Emoji
' ' : Noto Serif CJK JP
'世界' : Noto Serif CJK JP
```

`$ fontwhich -l ja`

```
Primary Sans font for ja is: "Noto Sans CJK JP"
```

`$ fontwhich --utf8 🌳`

```
4 bytes;
'🌳' [f0 9f 8c b3] : Noto Color Emoji
```

`$ fontwhich --unicode αβ१२`

```
10 bytes; 2 pango items
'αβ' : Noto Sans
α <U+03B1>: GREEK SMALL LETTER ALPHA [Greek]
β <U+03B2>: GREEK SMALL LETTER BETA [Greek]
'१२' : Noto Sans Devanagari
१ <U+0967>: DEVANAGARI DIGIT ONE [Devanagari]
२ <U+0968>: DEVANAGARI DIGIT TWO [Devanagari]
```

One can use both options together:

`$ fontwhich --utf8 🍊 --unicode`

```
4 bytes;
'🍊' [f0 9f 8d 8a] : Noto Color Emoji
🍊 <U+1F34A>: TANGERINE [Common]
```


## Building and installation
On Fedora, install system deps with `cabal-rpm builddep`.

C library dependencies:

- Fedora: cairo-devel pango-devel gobject-introspection-devel
- Ubuntu: libcairo2-dev libpango1.0-dev libgirepository1.0-dev

Then:
```
$ cabal install
```
or
```
$ stack install
```

There is a copr repo: <https://copr.fedorainfracloud.org/coprs/petersen/fontwhich/>

## Misc
Initial code assisted with Gemini 3.1.

The tool is related conceptually to the C project <https://github.com/sudipshil9862/whichfont>.

"fontwhich" as in "sandwich" but with fonts.

## Collaborate

The code is distributed under GPLv3+.

Repository: <https://github.com/juhp/fontwhich>
