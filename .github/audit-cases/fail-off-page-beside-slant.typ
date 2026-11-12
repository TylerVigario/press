// A paragraph placed past the paper's right edge, on a page with a note turned 30°: the note's
// words, cut differently by the two reads, are not off the paper, and the paragraph is.
// expect: page 1 has text off the paper, which prints on no page: The placed paragraph.
#import "/lib.typ": *
#show: brief.with(title: [Rack power], author: "press")

#v(1in)
#align(center, rotate(30deg, box(width: 2in)[Feed B is the spare; leave it unplugged.]))
#place(top + left, dx: 9in, dy: 6in)[The placed paragraph.]
