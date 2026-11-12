// A note of two lines turned 30°, wholly on the paper. poppler cuts slanted text into pieces of
// words, and cuts it differently within the paper and through the off-page pass's wide crop:
// "Bi st" against "B is t", the same text.
#import "/lib.typ": *
#show: brief.with(title: [Rack power], author: "press")

#v(1in)
#align(center, rotate(30deg, box(width: 2in)[Feed B is the spare; leave it unplugged.]))
