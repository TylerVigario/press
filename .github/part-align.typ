// A short line, then a flow and a line aligned right, in the body of each part a document writes
// one in, for part-align.sh; and a line aligned right outside any part, at the column's own edge.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

#align(right)[Columnend]

// Its words begin with the part's name. Each line is far narrower than the part, so a body only as
// wide as its widest line could neither centre the flow on the part nor end the line aligned right
// at its edge.
#let body(p) = [
  #(p + "left") is short.

  #flow(p + "mid")

  #align(right)[#(p + "end")]
]
#callout(label: [Calloutlabel], body("Callout"))
#panel(label: [Panellabel], body("Panel"))
#unit([Unitlabel], "note", [Unitlead holds.], body("Unit"))
#item(1, [Itemtitle], body("Item"))
#decision(1, [Decisionquestion], body("Decision"))
#addendum([2026-11-05], body("Addendum"), label: [Addendumlabel])
