// A character no face draws, read from a data file: it is in no source to scan, and the audit
// still finds it.
// expect: is MISSING a character no face draws: 漢
#import "/lib.typ": *
#set document(title: [Glyph from data], author: "press")
#set page(..card)
#set text(font: face-text, size: sz.body)
#json("data/shops.json").at(0).name
