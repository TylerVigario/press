// A form's answer placed below its Letter blank, read from the copy with the scan hidden: the
// answer prints on no page, and the audit says so.
// expect: page 1 has text off the paper, which prints on no page: Jane Doe
#import "/lib.typ": *
#set document(title: [Scanned form, an answer off the page], author: "press")
#set text(font: face-text, size: sz.body)
#form(image("scan/scan.pdf"))[
  #place(top + left, dx: 112pt, dy: 82pt)[15 October 2026]
  #place(top + left, dx: 112pt, dy: 12in)[Jane Doe]
]
