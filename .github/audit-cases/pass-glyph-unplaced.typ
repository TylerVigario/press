// A character no face draws, in a string the page never prints: nothing is missing from the page.
#import "/lib.typ": *
#set document(title: [Glyph never placed], author: "press")
#set page(..card)
#set text(font: face-text, size: sz.body)
#let spare = "🔧"
Plain text.
