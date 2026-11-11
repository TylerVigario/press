// A band in paper-tint, press's palest tint, runs off the page's corner: it clips there as a rule
// would, and the audit says so.
// expect: has ink 0.00in from a paper edge
#import "/lib.typ": *
#show: base.with(title: [Edge], author: "press")

#place(top + left, dx: -card.margin.x, dy: -card.margin.top,
  block(width: 3in, height: 1in, fill: paper-tint))
The band runs off the top left corner.
