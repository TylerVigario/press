# Vendored fonts

Every face press vendors is Noto, one family whose faces are made to sit together.

| Family | Constant | Weights and styles vendored | Licence |
|---|---|---|---|
| Noto Sans | `face-text`, `face-sans`, `face-display` | Regular, Italic, Bold, BoldItalic | OFL-1.1 |
| Noto Sans Mono | `face-mono` | Regular, Bold — **no italic** | OFL-1.1 |
| Noto Sans Math | `face-math`, and the stacks' tail | Regular — **one weight** | OFL-1.1 |
| Noto Sans Symbols 2 | the stacks' tail | Regular — **one weight** | OFL-1.1 |
| Noto Sans Hebrew | the stacks' tail | Regular, Bold | OFL-1.1 |

`face-sans` is `face-text`, kept so a document that names it builds. All are under the SIL Open
Font License 1.1, which permits redistribution. Each project's licence text is in
`fonts/licenses/`, and travels with the fonts in every release bundle.

Each is its project's own release, its unhinted TTFs unchanged:

| Family | Release |
|---|---|
| Noto Sans | [notofonts/latin-greek-cyrillic](https://github.com/notofonts/latin-greek-cyrillic), `NotoSans-v2.015` |
| Noto Sans Mono | [notofonts/latin-greek-cyrillic](https://github.com/notofonts/latin-greek-cyrillic), `NotoSansMono-v2.014` |
| Noto Sans Math | [notofonts/math](https://github.com/notofonts/math), `NotoSansMath-v3.000` |
| Noto Sans Symbols 2 | [notofonts/symbols](https://github.com/notofonts/symbols), `NotoSansSymbols2-v2.008` |
| Noto Sans Hebrew | [notofonts/hebrew](https://github.com/notofonts/hebrew), `NotoSansHebrew-v3.001` |

## Why they are vendored

Typst does not perform metric substitution the way fontconfig does. On a machine without
Arial, `#set text(font: "Arial")` emits only `warning: unknown font family` and silently
ships in a fallback serif. Typst 0.15 has no deny-warnings flag, so that mistake reaches
the PDF. Vendoring plus `--ignore-system-fonts` removes the *machine's* fonts from the
picture, so output cannot vary by machine, and the exported `face-*` constants turn a
typo into an unknown-variable *error* rather than a warning.

**`--ignore-system-fonts` does not leave the vendored faces alone in the room.** Typst
carries its own embedded fonts — Libertinus Serif, New Computer Modern and DejaVu Sans Mono
among them — and they remain reachable as fallbacks under that flag. That is why the three
failure modes below all survive it.

## Three ways a font goes wrong here, in ascending order of quietness

| Level | What is missing | What Typst does |
|---|---|---|
| Family | The whole family | `warning: unknown font family`, falls back |
| Weight or style | One face of a present family | **Nothing.** Nearest available face, exit 0 |
| Glyph | One codepoint in a present face | **Nothing.** That glyph alone comes from typst's own fonts |

Only the first one tells you. The `face-*` constants solve the family level. The stacks
below solve the glyph level. **Nothing solves the weight level except reading the table.**

### Glyph level — why the faces are stacks

Each `face-*` constant is an array: the intended face, then a tail of the Noto faces that carry
what it does not — Noto Sans Math the arrows and operators, Noto Sans Symbols 2 the ticks,
crosses, boxes and warning signs, Noto Sans Hebrew the Hebrew. Without the tail, a codepoint
absent from the head face is drawn in one of typst's embedded faces — one stray serif glyph
mid-sentence, no warning.

Verified: `→` (U+2192) is not in Noto Sans. Set in Noto Sans alone it embedded
`LibertinusSerif-Regular`; in `face-text` it comes from Noto Sans Math.

**`face-mono` is the one stack whose tail changes metric class**, and that is a known
tradeoff rather than an oversight. A proportional glyph inside a monospace run nudges a
column out of alignment quietly, where a serif fallback would at least look wrong on
sight — and this file argues elsewhere that quieter failures are worse. It stands because
there is no second monospace face vendored to fall back to, and losing a glyph outright is
worse than losing alignment on one character. If a mono document ever depends on column
alignment for meaning, audit it and consider vendoring a wider mono.

### The stacks narrow this hole; they do not seal it

A codepoint absent from **every** vendored face still comes from Typst's own bundled
fonts, and `--ignore-system-fonts` does not touch those. Measured on press, at typst 0.15.1 and
0.14.0 alike:

| Character | Outcome |
|---|---|
| `✓` `✗` `▸` `⚠` `⚡` `☐` `⛔` `📋` `ℹ` `✈` `☎` `⌘` `★` | drawn by Noto Sans Symbols 2 or Noto Sans Math, vendored |
| `⚓` `♻` `⚙` | drawn from `DejaVuSansMono` |
| `⎋` | drawn from `NewCMMath-Regular` |
| `🔧` `🚗` `漢` | printed as an empty box, Noto Sans's mark for a glyph it does not have |

All at exit 0, with no warning. The audit names the substitutes, a face press does not vendor,
and the boxes, a character no face draws: the page prints something, but not what was typed,
and a printed sheet cannot be diffed against anything.

**So a symbol vocabulary is a vendoring decision, not a typing decision.** Before a
document commits to one — safety callouts, checkboxes, list markers — write a probe
containing every symbol it needs, build it, and audit it with `tools/check.sh`. Adopt the
symbols the vendored faces actually carry, or vendor a face that carries them and add it to
the table above.

### Scripts — where a word changes face

The stack covers a script the head face lacks letter by letter. Noto Sans carries Latin,
Cyrillic and Greek, monotonic and polytonic (τέκνον, ἀφίενταί), so a word of any of them stays
in one face; Hebrew, pointed or not, comes whole from Noto Sans Hebrew in the tail. Exit 0, and
the audit passes, because every face is vendored. Measured with `fc-query` on the kit's own
files, letters carried of each block:

| Block | Noto Sans | Noto Sans Mono | Noto Sans Hebrew |
|---|---|---|---|
| Greek and Coptic, U+0370–03FF (144) | 121 | 121 | 0 |
| Greek Extended, U+1F00–1FFF (256) | 233 | 233 | 0 |
| Hebrew, U+0590–05FF (112) | 0 | 0 | 88 |
| Cyrillic, U+0400–04FF (256) | 256 | 256 | 0 |

A document that sets a script none of these carries throughout needs a face that carries it,
vendored and added to the table above.

### Weight level — the table above is a constraint, not an inventory

**Requesting a weight or style that is not vendored fails silently and completely.** The
family name is correct, so nothing warns — Typst picks the nearest face it has, and the
build exits 0.

Verified: under a template, `#emph[`make all`]` sets its code in upright
`NotoSansMono-Regular`, Noto Sans Mono having no italic, and a `→` or `✓` in bold text comes
from Noto Sans Math or Symbols 2 at their one weight, Regular — no warning, exit 0, and the
audit says nothing, since every face is vendored. The stacks do not help here: a *family* is
present, so the fallback chain is never consulted.

So **check the table before using a weight or style.** An italic in `face-mono`, or a bold
arrow, means vendoring that file first — add it here in the same commit, or the next person
inherits a silent fallback.

The cheap check on any finished document:

```sh
pdffonts print/docs/thing.pdf
```

Every face listed should be one you intended. An unexpected name, or a missing one you
expected, is the bug — and it is invisible by any other means.
