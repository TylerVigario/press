// units-order.typ — units under "stacks", for .github/units-order.sh, which gives the case: a long
// unit first and five short ones, five short ones and a long one last, three alike, or the first
// again set 1em apart. Each unit's lead is its place in the order given: Unit 1, Unit 2 and on.
#import "/lib.typ": *

#let case = sys.inputs.at("case", default: "long-first")
#let (words, spacing) = (
  "long-first": ((100, 20, 20, 20, 20, 20), 6pt),
  "long-last": ((20, 20, 20, 20, 20, 100), 6pt),
  "alike": ((20, 20, 20), 6pt),
  "em": ((100, 20, 20, 20, 20, 20), 1em),
).at(case)

#show: brief.with(title: [Probe], author: "press")
#units(spacing: spacing,
  ..words.enumerate().map(((i, n)) => unit([Note], "note", [Unit #(i + 1)], lorem(n))))
