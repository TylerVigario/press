// A two-page blank filled in under brief, between two pages of the document's own:
// .github/form-fill.sh checks each form page's size and where each answer's ink lands.
#import "/lib.typ": *

// What a document draws on every page of its own, none of which may reach a form page.
#set page(header: [A header of the document's own],
  background: place(top + left, dx: 40pt, dy: 300pt, rect(width: 10pt, height: 10pt, fill: black)),
  foreground: place(top + left, dx: 40pt, dy: 330pt, rect(width: 10pt, height: 10pt, fill: black)))
#show: brief.with(title: [A form filled in], author: "press",
  preset: (paper: "us-letter", margin: (x: 1in, y: 1.5in)))

A page of the document's own, before the form.

#form(image("form-fill/blank.pdf", page: 1))[
  #place(dx: 100pt, dy: 200pt, rect(width: 20pt, height: 10pt, fill: black, stroke: none))
  #tick(300pt, 400pt)
  #place(dx: 72pt, dy: 500pt, box(width: 60pt)[an answer much longer than the sixty points of its blank])
]
#form(image("form-fill/blank.pdf", page: 2))[
  #place(dx: 300pt, dy: 300pt, rect(width: 30pt, height: 5pt, fill: black, stroke: none))
]

And one after it.
