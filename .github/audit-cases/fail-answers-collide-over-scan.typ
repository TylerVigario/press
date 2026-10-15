// Two answers set on each other over a marked scan: hiding the scan must not hide this.
// expect: prints text on text
#import "/lib.typ": *
#set document(title: [Scanned form, answers colliding], author: "press")
#set page(paper: "us-letter", margin: 0pt)
#set text(font: face-text, size: sz.body)
#place(top + left, scan(image("scan/scan.pdf", width: 100%, height: 100%)))
#place(top + left, dx: 112pt, dy: 82pt)[Jane Doe]
#place(top + left, dx: 116pt, dy: 85pt)[15 October 2026]
