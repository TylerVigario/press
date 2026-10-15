// The same form with its scan not marked: the audit reads the scan as the document's own.
// expect: draws from fonts that are NOT vendored
#import "/lib.typ": *
#set document(title: [Scanned form, unmarked], author: "press")
#set page(paper: "us-letter", margin: 0pt)
#set text(font: face-text, size: sz.body)
#place(top + left, image("scan/scan.pdf", width: 100%, height: 100%))
#place(top + left, dx: 112pt, dy: 82pt)[Jane Doe]
