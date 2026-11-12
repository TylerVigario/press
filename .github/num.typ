// num() over counts and amounts, for num.sh: one number to a line, each as typst gives it, and
// then one grouped with a space, through its words. Page 2 sets a figure grouped with a space,
// and then with a thin space, after a gap that widens by 3pt across the 216pt line, so in some
// paragraphs it falls at the line's end, where it must stay whole: 72 paragraphs for each.
#import "/lib.typ": *

#set page(width: 4in, height: auto, margin: 0.5in)
#for n in (999, 1000, 3465, 12480, 1234567, -3465, 1234.5, decimal("1234567.50"),
  decimal("-1000.10")) [#num(n) \ ]
#num(1234567, words: (thousands: [ ]))

#pagebreak()
#for sep in ([ ], [#sym.space.thin]) {
  for pad in range(0, 216, step: 3) [
    The herd came to #h(pad * 1pt) #num(1234567, words: (thousands: sep)) cows. #parbreak()
  ]
}
