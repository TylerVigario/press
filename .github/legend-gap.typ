// For legend-gap.sh: a brief whose legend's note ends in the word Noteend, pushed right by a box
// `push` points wide, given through --input, and whose one chip is the word Chipword, so
// pdftotext gives each a box of its own and the space between the two columns is read between
// them.
#import "/lib.typ": *

#let push = float(sys.inputs.at("push", default: "0")) * 1pt
#show: brief.with(title: [Legend], author: "Sam Example", legend: (
  [Colour is state: each chip says how far its item has come #box(width: push)Noteend],
  [Chipword],
))

One line.
