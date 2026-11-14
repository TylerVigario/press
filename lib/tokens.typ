// press's tokens: colours, faces, the type scale and the page presets, and the version of
// press, read from press.toml. Every other file in lib/ imports this one.

// The oldest typst press works with, from press.toml. Read as files rather than as a package,
// nothing else would refuse an older typst, which would instead fail on whatever it lacks.
#let _manifest = toml("../press.toml")
#assert(sys.version >= version(.._manifest.typst.split(".").map(int)),
  message: "press needs typst " + _manifest.typst + " or newer; this is typst "
    + str(sys.version))

// The version of press a document was set with, read from press.toml in press's folder, so a
// page that prints it always names the press it was built with. Not `version`: that is
// typst's own, and `import *` would shadow it.
#let press-version = _manifest.version

// Ink & rules
//
// Contrast on white, measured, because a page must read on PAPER too, and a
// screen flatters grey that toner does not. Toner also gains — small type prints
// slightly heavier and lighter in colour than it renders — so screen-legible is
// the floor here, not the target.
//
//   ink        17.85:1   body
//   ink-soft    8.33:1   secondary
//   ink-faint   6.40:1   tertiary
//
// ink-faint is the lightest ink, at the smallest size, in italic, doing real
// work (stamp()'s closing line, and the footer): three legibility costs stacked
// on the same run. So it sits above the 4.5:1 body floor with room to spare,
// chosen against a printed sheet, and the hierarchy still reads because the
// gaps between the three stay wide.
#let ink = rgb("#0f172a")
#let ink-soft = rgb("#454f5b")
#let ink-faint = rgb("#55606d")
#let rule-hair = rgb("#c3cbd4")
#let rule-mid = rgb("#a3aeba")
#let paper-tint = rgb("#f5f7f9")

// Accents
#let slate = rgb("#1a4e8a")
#let slate-tint = rgb("#e7eef6")
#let steel = rgb("#41566b")

// Semantic
#let ok = rgb("#2e7d4f")
#let ok-tint = rgb("#e6f2ea")
#let warn = rgb("#a05a0e")
#let warn-tint = rgb("#f9efdf")
#let bad = rgb("#a3271d")
#let bad-tint = rgb("#f7e6e4")

// Faces — constants, never strings at the call site (lib.typ's header says why).
//
// Each is a STACK: the head is the intended face, the tail is a vendored
// fallback for glyphs the head does not carry. The tail is not cosmetic. Typst
// falls back PER GLYPH to its own bundled fonts when the requested family lacks a
// codepoint — silently, no warning, exit 0 — so a sans document ships stray serif
// glyphs, or none, and nothing says so. Verified: U+2192 (→) is absent from Noto
// Sans, and set in it alone, typst draws it from its own LibertinusSerif.
//
// Every face is Noto, one family made to sit together. The tail is the Noto faces
// that carry what Noto Sans does not: Noto Sans Math the arrows and operators,
// Noto Sans Symbols 2 the ticks, crosses, boxes and warning signs, and Noto Sans
// Hebrew the Hebrew. Mono falls back to Noto Sans rather than to a serif: the
// wrong width beats the wrong species. face-sans is face-text, kept so a document
// that names it builds; face-math sets equations, which typst would otherwise set
// in its own serif math face.
#let _tail = ("Noto Sans Math", "Noto Sans Symbols 2", "Noto Sans Hebrew")
#let face-text = ("Noto Sans", .._tail)
#let face-sans = face-text
#let face-display = ("Noto Sans", .._tail)
#let face-mono = ("Noto Sans Mono", "Noto Sans", .._tail)
#let face-math = ("Noto Sans Math",)

// Type scale — pick a step rather than inventing a size inline.
//
// Sized for PAPER, not for a screen you can zoom: type that reads fine at 150% on
// a monitor is mean at arm's length on a sheet, so body is 11pt and the smallest
// step 8.6pt.
//
// A document that does not fit should change its layout or its page preset — it
// must not set its type smaller to fit. Type too small to read comfortably is
// not a document that fits; it is one that failed in a way that only shows up
// on paper.
#let sz = (
  micro: 8.6pt, fine: 9.4pt, small: 10.2pt, body: 11pt,
  lead: 12.5pt, head: 14.5pt, title: 21pt, hero: 28pt,
)

// Page geometry presets. A template takes one as its `preset`, `brief.with(preset: dense)`, and
// a document that lays out its own page spreads one, `#set page(..dense)`, so the page is
// visibly set where it is composed.
//
// Sized so that PRINTING AT 100% IS SAFE. The page is exactly US Letter, so
// "actual size" needs no scaling — but consumer printers cannot print to the
// paper edge, and that unprintable band is set in hardware with no dialog
// option on most of them. Everything here therefore keeps ink at least 0.5in
// from every edge, clear of press's own calibration below; a printer whose band
// is wider at an edge is set by its own, which widens these margins to clear
// it. "Fit to page" is then never necessary, and should never be used: it
// scales the sheet down and undoes the type sizes above.
//
// The bottom margin is deliberately larger than the top. The footer sits INSIDE
// the bottom margin, so a symmetric margin puts the footer closer to the edge
// than anything else on the page — measured at 0.23in while the margin claimed
// 0.5in, which is inside the dead band on most hardware. footer-descent is
// pinned here rather than left at its 30%-of-margin default, so the clearance
// is a fixed number instead of a consequence of the margin.
#let dense = (
  paper: "us-letter", margin: (x: 1.5cm, top: 1.4cm, bottom: 1.95cm),
  footer-descent: 0.35cm,
)
#let reading = (
  paper: "us-letter", margin: (x: 1.05in, top: 0.95in, bottom: 1.05in),
  footer-descent: 0.2in,
)
#let card = (
  paper: "us-letter", margin: (x: 0.55in, top: 0.55in, bottom: 0.75in),
  footer-descent: 0.12in,
)

// A colour's contrast on white, WCAG's, from its sRGB components: 21 for black, 1 for white.
#let _linear(c) = if c <= 0.04045 { c / 12.92 } else { calc.pow((c + 0.055) / 1.055, 2.4) }
#let _contrast(colour) = {
  let (r, g, b) = rgb(colour).components(alpha: false).map(c => _linear(c / 100%))
  1.05 / (0.2126 * r + 0.7152 * g + 0.0722 * b + 0.05)
}

// press's inks, its tints and its rule colours, by name: the presets a calibration reaches.
#let _inks = (ink: ink, ink-soft: ink-soft, ink-faint: ink-faint, slate: slate, steel: steel,
  ok: ok, warn: warn, bad: bad)
#let _tints = (paper-tint: paper-tint, slate-tint: slate-tint, ok-tint: ok-tint,
  warn-tint: warn-tint, bad-tint: bad-tint)
#let _rules = (rule-hair: rule-hair, rule-mid: rule-mid, slate: slate, ink: ink)

// The calibration the presets are set for, a printer's numbers as the calibration sheet reads
// them, which every template takes by default. A template's `calibration` sets a printer's own,
// each number it leaves out taking this one's, and press's functions take every preset from it.
//
// `edges` is how near each edge of the paper the printer starts to print, its band, readings 2
// and 3: every preset keeps its ink, a header or footer included, at least that far from each
// edge, and the audit fails ink nearer. `brief.with(calibration: (edges: (bottom: 17mm)))`
// widens the bottom margin by as much as 17 mm exceeds the bottom here, and the audit fails ink
// within 17 mm of the bottom edge. A band narrower than this one leaves the margins as they are
// and lets the audit pass ink nearer that edge.
//
// `ink` is the lightest text ink that reads, reading 4, as its contrast on white: every ink of
// press's lighter than it is darkened, its hue kept, until it reaches it. `fill` is the palest
// fill that prints even, reading 5: every tint paler than it is darkened to it. `rule` is the
// thinnest rule that prints unbroken in each of press's rule colours, reading 6: every stroke a
// part draws is at least the width of the darkest of those colours no darker than its own.
// Here, each is what press uses now, so nothing changes until a printer's own are given: its
// lightest ink, ok's, its palest tint, paper-tint's, and the thinnest rule it draws in each.
//
// A repository whose documents print on one printer writes its numbers once, in a file its
// documents or its shared template import, and calibrated() hands back the presets set for them,
// for what a document draws itself.
#let calibration = (
  edges: (top: 0.48in, bottom: 0.48in, left: 0.48in, right: 0.48in),
  ink: calc.min(.._inks.values().map(_contrast)),
  fill: calc.min(.._tints.values().map(_contrast)),
  rule: (rule-hair: 0.4pt, rule-mid: 0.5pt, slate: 0.5pt, ink: 0.5pt),
)
