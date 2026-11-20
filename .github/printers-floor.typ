// printers-floor.typ — ink 0.1in from each edge of the paper, in a document that declares no
// printer's bands of its own, for .github/printers.sh: the audit fails it at every edge, and says
// the band it holds each edge to, which must be press's own.
#set document(title: [Floor])
#set page(paper: "us-letter", margin: 0.1in)
#set text(font: "Noto Sans")
#place(top + center)[Top]
#place(bottom + center)[Bottom]
#place(left + horizon)[Left]
#place(right + horizon)[Right]
