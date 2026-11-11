// A paragraph placed wholly past the paper's right edge: it prints on no page and leaves no ink
// near an edge to measure, and the audit says so.
// expect: page 1 has text off the paper, which prints on no page: The placed paragraph.
#import "/lib.typ": *
#show: base.with(title: [Off the page], author: "press")

Visible text.
#place(top + left, dx: 9in)[The placed paragraph.]
