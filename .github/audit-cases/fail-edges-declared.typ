// A printer whose band at the right is 0.75in, declared as the document's calibration: a line of
// ink 0.6in from the right edge clears press's own 0.48in, but not the band, and the audit says so.
// expect: from its right edge, inside the 0.75in band
#import "/lib.typ": *
#show: base.with(title: [Edges], author: "press", calibration: (edges: (right: 0.75in)))

// The calibration widens the right margin by the 0.27in its band exceeds press's, so the line is
// placed that much further out, to end 0.6in from the edge.
#place(top + right, dx: card.margin.x + 0.27in - 0.6in,
  text(size: sz.small)[A line 0.6in from the right.])
The page's own text keeps to its margin.
