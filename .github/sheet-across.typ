// sheet-across.sh's probe. A sheet across two columns that runs onto a second page, then, on a
// page of its own, one that fits on a page with a first row tall enough to hold several others.
#import "/lib.typ": *
#set page(paper: "us-letter", margin: 0.75in)
#set text(font: face-text, size: sz.small)

#sheet((1fr, auto), ([Room], [Key]), across: 2,
  ..range(1, 121).map(i => ([R#i], [K#i])).flatten())
#pagebreak()
#sheet((1fr, auto), ([Room], [Key]), across: 2,
  [T1 #lorem(60)], [K1], ..range(2, 9).map(i => ([T#i], [K#i])).flatten())
