// A character no face draws, written as an escape: the source holds only ASCII, and the audit
// still finds it.
// expect: is MISSING a character no face draws: 漢
#import "/lib.typ": *
#set document(title: [Glyph from an escape], author: "press")
#set page(..card)
#set text(font: face-text, size: sz.body)
Tea \u{6f22} shop
