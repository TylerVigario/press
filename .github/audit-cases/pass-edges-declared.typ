// A printer whose band at the top is 0.2in, declared as the document's calibration: a line of
// ink 0.3in below the top edge prints there, nearer than press's own 0.48in, and the audit passes
// it.
#import "/lib.typ": *
#show: base.with(title: [Edges], author: "press", calibration: (edges: (top: 0.2in)))

#place(top + left, dy: 0.3in - card.margin.top, text(size: sz.small)[A line 0.3in from the top.])
The page's own text starts at its margin.
