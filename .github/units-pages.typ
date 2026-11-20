// units-pages.typ — a group under "stacks" that runs past its page, for .github/units-pages.sh,
// which gives the case: six units of content after a page of prose, six units as unit() sets
// them, a unit taller than a page among three that fit, a group begun near the page's foot, a
// unit taller than what is left of the page but shorter than a column, as unit() sets it and
// as content, seventeen units over three pages, and the six again 1em apart and 2% of the page
// apart. Each unit starts with its place in the order given, Unit 1, Unit 2 and on, and ends with
// Endmark and the same number.
#import "/lib.typ": *

#let case = sys.inputs.at("case", default: "plain")
#let (before, words, spacing, part) = (
  "plain": (300, (110,) * 6, 6pt, false),
  "unit": (300, (110,) * 6, 6pt, true),
  "tall": (100, (60, 1500, 60, 60), 6pt, true),
  "foot": (520, (60,) * 5, 6pt, true),
  "deep": (430, (60, 250, 60, 60), 6pt, true),
  "deep-plain": (430, (60, 250, 60, 60), 6pt, false),
  "long": (50, (40, 120, 80, 200, 60, 90, 150, 30, 70, 110, 90, 60, 140, 50, 100, 80, 120), 6pt,
    true),
  "em": (300, (110,) * 6, 1em, true),
  "percent": (300, (110,) * 6, 2%, true),
).at(case)

#show: brief.with(title: [Probe], author: "press")
#lorem(before)

#units(spacing: spacing, ..words.enumerate().map(((i, n)) => {
  let body = [#lorem(n) Endmark #(i + 1)]
  if part { unit([Note], "note", [Unit #(i + 1)], body) } else { [Unit #(i + 1). #body] }
}))
