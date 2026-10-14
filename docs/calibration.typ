// Print calibration sheet for the press token set.
//
// Print this TWICE on the paper you actually use — once at normal quality,
// once in the printer's economy/draft mode — and compare the two by eye. It
// exercises every ink, size, tint and rule weight in the library, so whatever
// the printer degrades shows up here rather than in a document you needed.
//
// Duplex it. Page 2 carries a heavy solid field positioned to sit behind the
// observation window on page 1, which is how you read show-through honestly.
//
//   just build docs/calibration.typ

#import "@tylervigario/press:0.2.0": *

#set page(..card, footer: context {
  set text(size: sz.micro, fill: ink-faint)
  grid(columns: (1fr, auto),
    align(left)[press calibration · print at Actual size, duplex, both quality modes],
    align(right)[#updated() · #counter(page).display("1 / 1", both: true)])
})
#set text(font: face-text, size: sz.small, fill: ink, lang: "en")
#set par(leading: 0.52em, spacing: 0.55em)
#show raw: set text(font: face-mono, size: sz.micro)
#show link: link-note

#grid(columns: (auto, 1fr), align: (left + bottom, right + bottom),
  text(font: face-display, size: sz.title, weight: 700)[Print calibration],
  text(size: sz.fine, fill: ink-soft)[press #press-version · US Letter · actual size])
#v(-3pt)
#line(length: 100%, stroke: 2pt + slate)
#v(4pt)
#text(size: sz.micro, fill: ink-soft)[
  Print once normal, once economy. Mark the first row you would not want to read at arm's
  length — that row is your floor, and any document that relies on it needs changing.
]
#v(7pt)

#band-strong([Ink ladder — every ink at every size], "read this first", color: bad)

#let sample(colour) = {
  set text(fill: colour)
  stack(spacing: 4pt,
    text(size: sz.micro)[micro 8.6 — The quick brown fox jumps over the lazy dog · 0123456789],
    text(size: sz.fine)[fine 9.4 — The quick brown fox jumps over the lazy dog · 0123456789],
    text(size: sz.small)[small 10.2 — The quick brown fox jumps over the lazy dog],
    text(size: sz.body)[body 11 — The quick brown fox jumps over the lazy],
  )
}

#table(
  columns: (auto, 1fr),
  stroke: 0.4pt + rule-hair,
  inset: (x: 6pt, y: 6pt),
  align: (left + horizon, left + horizon),
  [#text(size: sz.fine, weight: 700)[ink] #linebreak()
   #text(size: sz.micro, fill: ink-soft)[17.85:1]], sample(ink),
  [#text(size: sz.fine, weight: 700)[ink-soft] #linebreak()
   #text(size: sz.micro, fill: ink-soft)[8.33:1]], sample(ink-soft),
  [#text(size: sz.fine, weight: 700)[ink-faint] #linebreak()
   #text(size: sz.micro, fill: ink-soft)[6.40:1]], sample(ink-faint),
  [#text(size: sz.fine, weight: 700)[slate] #linebreak()
   #text(size: sz.micro, fill: ink-soft)[8.40:1]], sample(slate),
)
#v(3pt)
#text(size: sz.micro, fill: ink-soft)[
  `ink-faint` is the one to watch. It is the lightest ink in the set and it carries the
  italic depth pointers, so it fails first in economy mode. If it survives here, nothing
  else in the library is at risk.
]
#v(8pt)

#band-strong([Tints, rules and solids — what dithering damages], "look for banding")

#let patch(label, fill-colour) = block(
  width: 100%, height: 30pt, fill: fill-colour, stroke: 0.4pt + rule-hair, radius: 1pt,
  inset: 4pt, text(size: sz.micro, fill: ink-soft)[#label],
)

#grid(columns: (1fr, 1fr, 1fr, 1fr, 1fr), gutter: 5pt,
  patch([paper-tint], paper-tint), patch([slate-tint], slate-tint),
  patch([ok-tint], ok-tint), patch([warn-tint], warn-tint), patch([bad-tint], bad-tint))
#v(5pt)
#text(size: sz.micro, fill: ink-soft)[
  These five are the palest fills in the set. Economy mode renders them with fewer dots, so
  they either go blotchy or disappear into the paper. Either failure is fine to accept — but
  decide it here, not mid-document.
]
#v(6pt)

#grid(columns: (1fr, 1fr), gutter: 10pt, align: (left + top, left + top),
  [#text(size: sz.micro, fill: ink-soft)[rule-hair 0.4pt] #v(3pt)
   #line(length: 100%, stroke: 0.4pt + rule-hair) #v(6pt)
   #text(size: sz.micro, fill: ink-soft)[rule-mid 0.7pt] #v(3pt)
   #line(length: 100%, stroke: 0.7pt + rule-mid) #v(6pt)
   #text(size: sz.micro, fill: ink-soft)[slate 2pt] #v(3pt)
   #line(length: 100%, stroke: 2pt + slate)],
  [#text(size: sz.micro, fill: ink-soft)[Solid bands — the ink-heavy element, and the one that
     shows through on duplex.] #v(4pt)
   #band-strong([Solid slate band], "role text sits here")
   #band-strong([Solid red band], "act", color: bad)],
)
#v(8pt)

#band-strong([Duplex show-through window], "hold to the light", color: steel)

#block(width: 100%, height: 76pt, stroke: (paint: rule-mid, dash: "dashed", thickness: 0.7pt),
  radius: 2pt, inset: 8pt)[
  #text(size: sz.micro, fill: ink-soft)[
    Page 2 carries a heavy solid field. Whatever you see inside this box is coming through the
    sheet from the other side. Judge it against the paper you actually stock — a heavier
    sheet is the fix, not a lighter design, because the bands are what make a section
    skippable at a glance.
  ]
]

#stamp[Reprint this whenever the paper, the printer or the token set changes.]

#pagebreak()

#align(center)[#text(size: sz.fine, fill: ink-faint, style: "italic")[
  Page 2 exists to be looked through, not read.
]]
#v(20pt)
#block(width: 100%, height: 300pt, fill: ink, radius: 2pt, inset: 12pt,
  text(size: sz.small, fill: white)[
    Solid field for the show-through test. Turn back to page 1 and look at the dashed window.
  ])
#v(14pt)
#text(size: sz.small)[
  A link, as `link-note` prints it: #link("https://github.com/TylerVigario/press")[the press
  source]. On a screen it clicks; on paper its address is in the footnote. Check that the
  underline survives economy mode, since it, not the colour, is what marks a link in greyscale.
]
