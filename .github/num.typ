// num() over counts and amounts, for num.sh: one number to a line, each as typst gives it, and
// then one grouped with a space, through its words.
#import "/lib.typ": *

#set page(width: 4in, height: auto, margin: 0.5in)
#for n in (999, 1000, 3465, 12480, 1234567, -3465, 1234.5, decimal("1234567.50"),
  decimal("-1000.10")) [#num(n) \ ]
#num(1234567, words: (thousands: [ ]))
