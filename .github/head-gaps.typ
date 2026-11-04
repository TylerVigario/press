// A header, a == heading and a résumé entry with its bullets, each measured, for head-gaps.sh,
// under the paragraph spacing and the space around headings that `--input spacing=` sets: what is
// inside each is the part's own, so none of them may change with it.
#import "/lib.typ": *

#let spacing = eval(sys.inputs.at("spacing", default: "0.8em"))
#show: brief.with(title: [Probe], author: "press")
#set par(spacing: spacing)
#show heading: set block(above: spacing, below: spacing)

#context [#metadata(measure(block(width: 5in, header(meta: [Site]))).height)<header>]
#context [#metadata(measure(block(width: 5in, heading(level: 2)[Label])).height)<heading>]
#context [#metadata(measure(block(width: 5in, {
  entry([Role], [Organisation], [2021 – present])
  list([What was done.], [What came of it.])
})).height)<entry>]
