// A character no vendored face draws, on the page: it vanishes, and the audit says so.
// expect: is MISSING a character present in the source
#import "/lib.typ": *
#set document(title: [Glyph missing], author: "press")
#set page(..card)
#set text(font: face-text, size: sz.body)
Clipboard: 📋
