// The stand-in blank .github/form-fill.sh fills in, in typst's own Libertinus, a face press does
// not vendor: a letter page and an A4 page, each with a label and a box, as a form has.
#set page(width: 8.5in, height: 11in, margin: 0pt)
#set text(size: 9pt)
#place(top + left, dx: 72pt, dy: 72pt)[Name]
#place(top + left, dx: 72pt, dy: 90pt, rect(width: 200pt, height: 14pt))
#pagebreak()
#set page(paper: "a4", margin: 0pt)
#place(top + left, dx: 72pt, dy: 72pt)[Signed]
