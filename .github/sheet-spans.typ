// For sheet-spans.sh: a sheet given typst's own table parts, a cell spanning two columns, one
// spanning two rows, a line and a footer; and on page 2 a sheet across two columns, whose middle
// rows a span ties together. Each word is one, so pdftotext gives each a box of its own.
#import "/lib.typ": *

#set page(width: 6in, height: 9in, margin: 0.5in)
#set text(font: face-text)

#sheet((2in, 1in, 2in), ([Itemhead], [Amounthead], [Notehead]),
  table.cell(colspan: 2)[Spanned], [Firstnote],
  table.cell(rowspan: 2)[Nuts], [Twelve], [Smallnote],
  [Thirty], [Largenote],
  table.hline(stroke: 1.5pt),
  table.footer(table.cell(colspan: 2)[Totalrow], [Footnote]),
)

#pagebreak()
#sheet((1fr, auto), ([Roomhead], [Keyhead]), across: 2,
  ..range(10).map(i => ([Room], [Key])).flatten(),
  table.cell(rowspan: 2)[Tied], [Tieda], [Tiedb],
  ..range(10).map(i => ([Room], [Key])).flatten(),
)
