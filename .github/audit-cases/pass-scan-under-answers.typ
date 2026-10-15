// A filled-in form: a scanned page marked with scan(), and an answer set over its blank. The
// scan's own face, text layer and edge-to-edge tint are not the document's, and are not findings.
#import "/lib.typ": *
#set document(title: [Scanned form], author: "press")
#set page(paper: "us-letter", margin: 0pt)
#set text(font: face-text, size: sz.body)
#place(top + left, scan(image("scan/scan.pdf", width: 100%, height: 100%)))
#place(top + left, dx: 112pt, dy: 82pt)[Jane Doe]
