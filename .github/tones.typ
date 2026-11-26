// tones.typ — a part that sets a tone's label on the tone's tint, for .github/tones.sh: a boxed
// chip, or a callout with a label, as --input part= names it, in the tone --input tone= names,
// alone on a page under base, with press's own calibration.
#import "/lib.typ": *

#let part = sys.inputs.at("part")
#let tone = sys.inputs.at("tone")
#show: base.with(title: [Tones])
#if part == "chip" { chip([SETTLED], tone) } else if part == "callout" {
  callout(label: [Settled], tone: tone)[The body under the label.]
} else { panic("tones.typ has no part " + part) }
