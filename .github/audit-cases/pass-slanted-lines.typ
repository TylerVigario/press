// Text of two lines turned to a slant: a RECEIVED stamp at -30°, and a note at 10° and at 45°.
// Nothing touches anything else, but each word's upright box holds far more than its slanted
// glyphs, so the boxes of two lines meet where no glyph does.
#import "/lib.typ": *
#show: brief.with(title: [Rack power], author: "press")

#place(top + right, dx: -0.6in, dy: 1.6in, rotate(-30deg,
  box(stroke: 1.5pt + bad, inset: 6pt, text(fill: bad, weight: "bold")[RECEIVED \ 7 Nov 2026])))

= How it works
The rack draws 2.4 kW from two feeds.

#for a in (10deg, 45deg) {
  v(0.9in)
  align(center, rotate(a, box(width: 2in)[Feed B is the spare; leave it unplugged.]))
}
