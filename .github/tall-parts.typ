// For tall-parts.sh, under brief: a code block, a unit, a decision and an item, each taller than a
// page, then a code block, a unit and an item that each fit on a page, but not in the room left
// on theirs. Each section starts a page. `--input breakable=true` lets the short ones break, so
// the script can show they meet a page turn.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")
#let br = if sys.inputs.at("breakable", default: "auto") == "true" { true } else { auto }

#raw(block: true, lang: "sh", range(90).map(i => "echo tall " + str(i)).join("\n"))

After the tall code.
#pagebreak()

#unit([Note], "note", [A long note], [Ubegins

#lorem(1400)

Uends])

After the tall unit.
#pagebreak()

#decision(1, [Which supplier?], [Dbegins

#lorem(1400)

Dends])

After the tall decision.
#pagebreak()

#item(1, [A long step])[Ibegins

#lorem(1400)

Iends]

After the tall item.
#pagebreak()

CSstart

#lorem(640)

#[
  #show raw.where(block: true): it => code(it, breakable: br)
  #raw(block: true, lang: "sh", range(30).map(i => "echo short " + str(i)).join("\n"))
]
#pagebreak()

USstart

#lorem(640)

#unit([Note], "note", [A short note], breakable: br, [USbegins

#lorem(300)

USends])
#pagebreak()

ISstart

#lorem(640)

#item(2, [A short step], breakable: br)[ISbegins

#lorem(300)

ISends]
