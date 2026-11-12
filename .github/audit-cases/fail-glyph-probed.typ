// A PDF placed without scan() stops the PDF/A compile, so the characters typed in the source are
// probed one by one: a character no face draws is found in a string the page never prints.
// expect: is MISSING a character present in the source: 📋
#import "/lib.typ": *
#set document(title: [Glyph probed], author: "press")
#set page(..card)
#set text(font: face-text, size: sz.body)
#let spare = "📋"
A figure made elsewhere:
#image("scan/scan.pdf", width: 2in)
