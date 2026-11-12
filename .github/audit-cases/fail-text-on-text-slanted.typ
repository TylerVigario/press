// A RECEIVED stamp turned to a slant and set across a line of text: slanted text printed on
// text is text on text, as upright text is.
// expect: prints text on text
#import "/lib.typ": *
#show: brief.with(title: [Rack power], author: "press")

#v(1in)
The rack draws 2.4 kW from two feeds, and each feed carries the whole load when the other fails.
#place(dx: 2in, dy: -0.45in, rotate(-30deg,
  box(stroke: 1.5pt + bad, inset: 6pt, text(fill: bad, weight: "bold")[RECEIVED \ 7 Nov 2026])))
