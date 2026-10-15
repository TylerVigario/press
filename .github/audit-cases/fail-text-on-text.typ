// Text placed over a line of text: the collision the overlap check exists to catch.
// expect: prints text on text
#import "/lib.typ": *
#set document(title: [Text on text], author: "press")
#set page(..dense)
#set text(font: face-text, size: sz.body)
First line of a paragraph that runs on.
#place(top + left, dy: 3pt)[Text placed over the first line.]
