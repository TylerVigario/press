// The stand-in blank's first page with the measuring grid on, every 18pt: .github/form-fill.sh
// checks the grid draws, and that the audit refuses the document for it and for nothing else.
#import "/lib.typ": *

#show: base.with(title: [A form measured], author: "press")

#form(image("blank.pdf", page: 1), probe: 18pt)[
  #place(dx: 100pt, dy: 200pt)[An answer]
]
