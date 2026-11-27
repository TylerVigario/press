// tint-text.typ — a part that sets text on one of press's tints, for .github/tint-text.sh: a boxed
// chip, a callout with a label, a unit, a code block, or a sheet of its head and one striped row,
// as --input part= names it, in the tone --input tone= names, alone on a page under base, given
// the calibration --input calibration= names: press's own (own), a fill of 1.3 (fill-1.3) or 1.5
// (fill-1.5), or a fill of 1.5 and an ink of 6 (fill-1.5-ink-6). With --input words=true, the part
// holds the document's own text in each of press's inks, a curled quote and an equation in each,
// and in each as calibrated() sets it for the calibration, as README has a document draw its own.
#import "/lib.typ": *

#let part = sys.inputs.at("part")
#let tone = sys.inputs.at("tone", default: "ok")
#let given = (
  own: calibration, "fill-1.3": (fill: 1.3), "fill-1.5": (fill: 1.5),
  "fill-1.5-ink-6": (fill: 1.5, ink: 6),
).at(sys.inputs.at("calibration"))
#let words = if sys.inputs.at("words", default: "false") == "true" {
  let set-for = calibrated(given)
  _inks.pairs().map(((name, c)) => text(fill: c)["#name" $x$]
    + [ ] + text(fill: set-for.at(name))["#name" $x$]).join[ ]
}

#show: base.with(title: [Tint text], calibration: given)
#if part == "chip" { chip([SETTLED #words], tone) } else if part == "callout" {
  callout(label: [Settled], tone: tone)[The body. #words]
} else if part == "unit" { unit([Settled], tone, [The lead.], [The body. #words]) } else if (
  part == "code") { code[The code. #words] } else if part == "sheet" {
  sheet((1fr, auto), ([Item #words], [Amount]), [A #words], [1])
} else { panic("tint-text.typ has no part " + part) }
