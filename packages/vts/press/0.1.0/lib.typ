// vts/press — the house apparatus for VTS printables.
//
//   #import "@vts/press:0.1.0": *
//
// 0.1.0 is the first version; this directory has never held another. It carries the composition vocabulary — `unit`, `chip`,
// `band-strong`, `dbadge`, `decision` — which had been copy-pasted between
// documents while the pipeline was still a prototype inside server-admin. None
// of them was ever document-specific; they lived in the documents only because
// that is where they were first written, and `unit` and `chip` had already gone
// byte-identical across three files. That is the same drift this pipeline
// exists to prevent, one level down.
//
// Released versions are immutable. A change goes in a NEW directory with a
// bumped `typst.toml` — consumers pin an exact version, and a silent edit
// underneath them is the failure packaging exists to prevent. Until a version's
// first release its directory takes additions: `updated()` came into 0.1.0 that way.
//
// What deliberately did NOT move: composition. Section order, page choice,
// which diagrams exist, how deep a document layers — that stays local. The
// library supplies vocabulary, the document writes the sentence.
//
// This library is ADDITIVE, not governing. Nothing here takes effect unless a
// document calls it: it sets no page and installs no show rule of its own
// accord, and assumes no layout. The document owns its page and takes whichever
// parts serve it. That inversion is deliberate — a template that owns the page
// is what forces every document with real layout needs to escape the system.
//
// "Not governing" limits what this library ENFORCES, never what it may OFFER. A
// styling helper a document opts into enforces nothing. Treating styling as out
// of scope leaves every document inventing its own, which is the copy-paste
// drift this package exists to end. It is a helper, not a governor: documents
// vary too much for it to be anything else.
//
// Fonts are vendored beside this file rather than named from the system.
// Typst does NOT perform metric substitution the way fontconfig does: on a box
// without Arial, `#set text(font: "Arial")` emits only `warning: unknown font
// family` and silently falls back to an embedded serif. Since 0.15 has no
// deny-warnings flag, that mistake ships. Hence: faces are exported constants
// below, so a typo is an unknown-variable ERROR, and callers pass `face-*`
// rather than a string.
//
// That covers the FAMILY level only, which is the loudest of three. A missing
// WEIGHT and a missing GLYPH each report nothing at all, and
// --ignore-system-fonts does not help because typst's own embedded fonts stay
// reachable. See the face block below, and FONTS.md for the full account. The
// constants are stacks rather than single names for that reason, and
// `just check` is what turns the silent two into something readable.

// ---------------------------------------------------------------- tokens ---

// Ink & rules
//
// Contrast on white, measured, because these are read on PAPER and a screen
// flatters grey that toner does not. Toner also gains — small type prints
// slightly heavier and lighter in colour than it renders — so screen-legible is
// the floor here, not the target.
//
//   ink        17.85:1   body
//   ink-soft    8.33:1   secondary
//   ink-faint   6.40:1   tertiary  — started at 3.04, below the 4.5:1 body floor;
//                                    5.51 still read as unpleasant on paper, so it
//                                    was lifted again against a printed sheet
//
// ink-faint was the reported failure: the lightest ink, at the smallest size,
// in italic, doing real work (the seedepth pointers and the footer). Three
// legibility costs stacked on the same run. It is now above the body floor with
// room to spare, and the hierarchy still reads because the gaps between the
// three stayed wide.
#let ink = rgb("#0f172a")
#let ink-soft = rgb("#454f5b")
#let ink-faint = rgb("#55606d")
#let rule-hair = rgb("#c3cbd4")
#let rule-mid = rgb("#a3aeba")
#let paper-tint = rgb("#f5f7f9")

// Accents
#let slate = rgb("#1a4e8a")
#let slate-tint = rgb("#e7eef6")
#let steel = rgb("#41566b")

// Semantic
#let ok = rgb("#2e7d4f")
#let ok-tint = rgb("#e6f2ea")
#let warn = rgb("#a05a0e")
#let warn-tint = rgb("#f9efdf")
#let bad = rgb("#a3271d")
#let bad-tint = rgb("#f7e6e4")

// Faces — constants, never strings at the call site (see header).
//
// Each is a STACK: the head is the intended face, the tail is a vendored
// fallback for glyphs the head does not carry. The tail is not cosmetic. Typst
// falls back PER GLYPH to its own bundled LibertinusSerif when the requested
// family lacks a codepoint — silently, no warning, exit 0 — so a sans document
// ships stray serif glyphs and nothing says so. Verified: U+2192 (→) is absent
// from Open Sans, and `→` in body text embedded LibertinusSerif-Regular, plus
// LibertinusSerif-Italic wherever the surrounding text was italic.
//
// Liberation Sans is the tail because it is already vendored and its coverage
// is broad. Mono falls back to Liberation Mono's own sans sibling rather than
// to a serif: the wrong width beats the wrong species.
#let face-sans = ("Liberation Sans",)
#let face-text = ("Open Sans", "Liberation Sans")
#let face-display = ("Montserrat", "Liberation Sans")
#let face-mono = ("Liberation Mono", "Liberation Sans")

// Type scale — pick a step rather than inventing a size inline.
//
// Sized for PAPER, not for a screen you can zoom. The first print of a real
// document came back "text is too small": the previous scale started at 7.6pt
// and put body at 9.6pt, which reads fine at 150% on a monitor and is mean at
// arm's length on a sheet. Every step moved up roughly 13%, keeping the ratios.
//
// A document that no longer fits after this should lose content to its depth
// layer, or change page preset — it must not drop back down the scale. Type too
// small to read comfortably is not a document that fits; it is one that failed
// in a way that only shows up on paper.
#let sz = (
  micro: 8.6pt, fine: 9.4pt, small: 10.2pt, body: 11pt,
  lead: 12.5pt, head: 14.5pt, title: 21pt, hero: 28pt,
)

// Page geometry presets. Spread at the call site — `#set page(..dense)` —
// so the document stays visibly in charge of its own page.
//
// Sized so that PRINTING AT 100% IS SAFE. The page is exactly US Letter, so
// "actual size" needs no scaling — but consumer printers cannot print to the
// paper edge, and that unprintable band is set in hardware with no dialog
// option on most of them. Everything here therefore keeps ink at least 0.5in
// from every edge, which clears the dead band on ordinary lasers and inkjets
// alike. "Fit to page" is then never necessary, and should never be used: it
// scales the sheet down and undoes the type sizes above.
//
// The bottom margin is deliberately larger than the top. The footer sits INSIDE
// the bottom margin, so a symmetric margin puts the footer closer to the edge
// than anything else on the page — measured at 0.23in while the margin claimed
// 0.5in, which is inside the dead band on most hardware. footer-descent is
// pinned here rather than left at its 30%-of-margin default, so the clearance
// is a fixed number instead of a consequence of the margin.
#let dense = (
  paper: "us-letter", margin: (x: 1.5cm, top: 1.4cm, bottom: 1.95cm),
  footer-descent: 0.35cm,
)
#let reading = (
  paper: "us-letter", margin: (x: 1.05in, top: 0.95in, bottom: 1.05in),
  footer-descent: 0.2in,
)
#let card = (
  paper: "us-letter", margin: (x: 0.55in, top: 0.55in, bottom: 0.75in),
  footer-descent: 0.12in,
)

// ----------------------------------------------------------------- parts ---

// `caps` is opt-out because upper() CORRUPTS case-carrying strings, and silently:
// "pH" becomes "PH", "iOS" becomes "IOS", and "µS" becomes "ΜS" — micro-sign
// turned into capital Mu, a different character entirely. Pass `caps: false`
// whenever the case of the label means something.
#let eyebrow(body, color: slate, caps: true) = text(
  size: sz.fine, weight: 700, tracking: 1.2pt, fill: color,
  if caps { upper(body) } else { body },
)

// Title row: name left, dateline right, rule beneath.
#let titlebar(title, meta, color: slate, face: face-display, size: sz.title) = {
  grid(
    columns: (auto, 1fr),
    align: (left + bottom, right + bottom),
    text(font: face, size: size, weight: 700, fill: ink)[#title],
    text(size: sz.fine, fill: ink-soft)[#meta],
  )
  v(-3pt)
  line(length: 100%, stroke: 1.6pt + color)
}

// A labelled hairline — cheaper than a heading when the label is enough.
#let band(label, color: slate) = {
  v(3pt)
  eyebrow(label, color: color)
  v(-2pt)
  line(length: 100%, stroke: 0.7pt + rule-hair)
  v(3pt)
}

#let tones = (
  note: (slate, slate-tint), ok: (ok, ok-tint),
  warn: (warn, warn-tint), bad: (bad, bad-tint),
)

// Tinted callout with a weighted left edge.
#let callout(body, tone: "note", label: none, size: sz.small) = {
  let pair = tones.at(tone)
  block(
    width: 100%, fill: pair.at(1), stroke: (left: 3pt + pair.at(0)),
    inset: (x: 10pt, y: 8pt),
  )[
    #if label != none [#eyebrow(label, color: pair.at(0)) #v(3pt)]
    #text(size: size)[#body]
  ]
}

// Bordered panel — for grids where a tint would shout.
#let panel(body, label: none, color: slate) = block(
  width: 100%, stroke: 0.6pt + rule-mid, inset: 10pt, radius: 1pt,
)[
  #if label != none [#eyebrow(label, color: color) #v(4pt)]
  #body
]

// Code block treatment. The document installs it; press never does:
//
//   #show raw: set text(font: face-mono, size: sz.micro)
//   #show raw.where(block: true): code
//
// Shading and a border, commands as plain lines, nothing per line. That is what
// documentation actually does — Google's developer style guide, MDN and GitLab
// all describe one block for related sequential commands — and it is what a
// reader recognises as a command listing without being taught.
//
// NOTHING PER LINE, deliberately, and for two reasons that are not aesthetic.
//
// It is not a convention anywhere. No style guide frames each command, and a
// reader meeting an invented pattern has to work out what it means first.
//
// It costs the reader their selection. Framing each command in its own box was
// tried on a real sheet and a PDF reader then highlighted the whole group when
// one command was clicked, forcing the reader to drag by hand. These sheets are
// read on screen as well as on paper. The mechanism inside the PDF was not
// established — the obvious candidates were measured and ruled out — but the
// behaviour was observed directly, and it is enough to settle the design.
//
// NO PROMPT AND NO LANGUAGE LABEL. `$`, `PS>` and a `# pwsh` first line all put
// characters on the page that are not part of the command, and every one of them
// has to be edited out after a paste. MDN's guidance is the same. Where a
// document genuinely mixes shells, say so in the prose around the block.
//
// breakable is opt-in. A command split across a page turn is a command with no
// second half, so the default refuses to break; a long listing that legitimately
// spans pages passes `breakable: true` through a closure:
//
//   #show raw.where(block: true): it => code(it, breakable: true)
#let code(body, breakable: false) = block(
  width: 100%, fill: paper-tint, stroke: 0.6pt + rule-mid,
  inset: (x: 7pt, y: 6pt), radius: 1.5pt, breakable: breakable,
  body,
)

// Numbered entry: marker, title, explanation.
#let item(n, title, body, color: slate, size: sz.small) = block(
  width: 100%, breakable: false, inset: (bottom: 6pt),
)[
  #text(size: size, weight: 700, fill: color)[#n]
  #h(5pt)
  #text(size: size, weight: 700)[#title]
  #v(2pt)
  #text(size: size)[#body]
]

// Hairline table with a tinted header row.
#let matrix(head, ..rows) = table(
  columns: (auto, 1fr),
  stroke: 0.4pt + rule-hair,
  inset: (x: 7pt, y: 5.5pt),
  fill: (_, y) => if y == 0 { slate-tint } else { none },
  ..head.map(h => text(size: sz.fine, weight: 700)[#h]),
  ..rows.pos().map(c => text(size: sz.fine)[#c]),
)

// a → b → c, for pipelines.
#let flow(..steps) = align(center)[
  #box(inset: (x: 9pt, y: 6pt), stroke: 0.6pt + rule-mid, radius: 1pt)[
    #text(size: sz.small)[
      #steps.pos().join([ #text(fill: ink-faint)[#sym.arrow.r] ])
    ]
  ]
]

#let stamp(body) = {
  v(4pt)
  line(length: 100%, stroke: 0.5pt + rule-hair)
  v(2pt)
  text(size: sz.micro, fill: ink-faint, style: "italic")[#body]
}


// When the page's content last changed, as press's `build` stamps it (tools/stamp.sh).
// A rebuild that changes nothing on the page keeps the old time, so a newer time than the
// copy on the shelf means reprint, and the same time means that copy is current. Put it in
// the footer, where every page carries it: a page parted from its stack still says which
// edition it is. Outside `just build` -- typst watch, a bare typst compile -- there is no
// stamp, and it says so rather than inventing one.
#let updated() = {
  let s = sys.inputs.at("press-updated", default: none)
  if s == none { [not stamped (built outside just build)] } else { [updated #s] }
}

// ----------------------------------------------------------- composition ---
// Promoted out of individual documents while this was still a prototype.
// Generic by nature — a labelled bounded block, a state chip, a reversed band,
// a numbered badge.

// The workhorse. A bounded unit of exactly one idea: a label to navigate by, a
// bold LEAD that is the highlight pre-made, and a body as long as the idea
// actually needs. There is no length cap on purpose — capping length lets the
// format decide what the reader is allowed to know.
// `caps` forwards to the label's `eyebrow` — see the note there. This is the
// most-used call in the vocabulary, so it is where the uppercasing does the most
// damage: `unit([pH], "warn")` renders "PH" with nothing to indicate it happened.
#let unit(label, tone, lead, body, caps: true, breakable: false) = {
  let pair = tones.at(tone)
  block(width: 100%, breakable: breakable, stroke: (left: 2.5pt + pair.at(0)),
        fill: paper-tint, inset: (x: 8pt, y: 6.5pt))[
    #eyebrow(label, color: pair.at(0), caps: caps)
    #v(2.5pt)
    #text(size: sz.fine, weight: 700)[#lead]
    #if body != none [ #v(2.5pt) #text(size: sz.fine)[#body] ]
  ]
}

// Inline state marker — use in a legend so colour reads as meaning.
#let chip(label, tone) = {
  let pair = tones.at(tone)
  box(fill: pair.at(1), stroke: 0.5pt + pair.at(0), inset: (x: 4pt, y: 2pt), radius: 1pt,
      text(size: sz.micro, weight: 700, fill: pair.at(0))[#label])
}

// Reversed section band. `role` rides inside it — decide / design / reference —
// so that skipping a section is a deliberate act rather than an accident.
// `caps` as on `eyebrow` — see the note there. A band titled "pH and conductivity"
// silently becomes "PH AND CONDUCTIVITY" without it.
#let band-strong(title, role, color: slate, caps: true) = {
  v(2pt)
  block(width: 100%, fill: color, inset: (x: 8pt, y: 4.5pt), radius: 1pt)[
    #grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      text(size: sz.fine, weight: 700, tracking: 1.2pt, fill: white)[#if caps { upper(title) } else { title }],
      text(size: sz.micro, fill: white.darken(12%), style: "italic")[#role])
  ]
  v(5pt)
}

#let dbadge(n, color: bad) = box(
  fill: color, radius: 50%, inset: (x: 4.5pt, y: 3pt),
  text(size: sz.fine, weight: 700, fill: white)[#n],
)

// A badged question with its note — for anything the reader must answer.
#let decision(n, q, note, color: bad) = block(
  width: 100%, breakable: false, inset: (bottom: 5.5pt),
)[
  #grid(columns: (auto, 1fr), gutter: 6pt, align: (left + top, left + top),
    dbadge(n, color: color),
    [
      #text(size: sz.fine, weight: 700)[#q]
      #v(1.5pt)
      #text(size: sz.fine, fill: ink-soft)[#note]
    ])
]

// A wide data table. Promoted after the identical helper appeared in five
// documents across two repos — `inventory` and `sheet` here, `sheet-table` in
// three pool documents, byte-identical in most of them. The house `matrix` is
// deliberately two-column; this is what every document reached for when it had
// more columns than that.
//
// `cols` is passed through to `table.columns` so the document keeps control of
// widths. Header row is bold on a slate tint, body rows zebra-striped.
//
// `size` exists because hardcoding it was pushing documents into writing their own
// per-cell wrapper just to get a different one. The pool lane's `cell()` helper was
// exactly that, and rather than promote the workaround the cause is fixed here.
//
// The header goes through `table.header`, which repeats it on every page the table
// spans. Without it a table crossing a page break leaves the reader with bare rows
// and no column labels — and on paper there is no scrolling back. `matrix` gets away
// without it because two-column comparisons are short; `sheet` is explicitly the
// many-column data table, which is the shape that breaks.
#let sheet(cols, head, size: sz.micro, ..rows) = table(
  columns: cols,
  stroke: 0.4pt + rule-hair,
  inset: (x: 5pt, y: 4pt),
  fill: (_, y) => if y == 0 { slate-tint } else if calc.odd(y) { paper-tint } else { none },
  table.header(..head.map(h => text(size: size, weight: 700)[#h])),
  ..rows.pos().map(c => text(size: size)[#c]),
)

// Cross-reference to the depth layer: "detail on p.N" without hard-coding N.
#let seedepth(label) = text(size: sz.fine, fill: ink-faint, style: "italic")[
  #sym.arrow.r detail: #label
]


// Lay out a set of units. The document still owns its page; this owns only how a
// GROUP packs, which is the one thing every document was re-deriving by hand.
//
//   "stacks"  two columns filled independently and balanced by MEASURED height.
//             Nothing is padded to match a neighbour, which is the failure of a
//             row grid: a row is as tall as its tallest cell, so a short unit
//             beside a long one leaves the gap under it.
//   "grid"    row-major cells. Keeps units aligned across a row — correct when
//             the pairing means something, and the source of that gap when it
//             does not.
//   "single"  one column, full width.
//
// Balancing measures at the real column width inside `layout`, because a unit's
// height depends on where it wraps. Counting source lines guesses at that and is
// wrong wherever prose wraps differently from markup.
#let units(..items, pack: "stacks", gutter: 9pt, spacing: 6pt) = {
  // Fail on an unknown value rather than falling through. `pack: "stack"` would
  // otherwise render the default and look deliberate, which is the failure mode
  // this whole package is meant to make loud.
  assert(pack in ("stacks", "grid", "single"),
         message: "units(pack:) expects \"stacks\", \"grid\" or \"single\"; got \"" + pack + "\"")
  let us = items.pos()
  let stack(col) = {
    for (i, u) in col.enumerate() {
      u
      if i + 1 < col.len() { v(spacing) }
    }
  }

  if us.len() == 0 { return }
  if pack == "single" { return stack(us) }
  if pack == "grid" {
    return grid(columns: (1fr, 1fr), gutter: gutter, row-gutter: spacing, ..us)
  }

  // pack == "stacks", guaranteed by the assert above.
  layout(size => {
    let w = (size.width - gutter) / 2
    let left = ()
    let right = ()
    let hl = 0pt
    let hr = 0pt
    for u in us {
      let h = measure(box(width: w, u)).height
      if hl <= hr { left.push(u); hl += h } else { right.push(u); hr += h }
    }
    grid(columns: (1fr, 1fr), gutter: gutter, align: top,
         stack(left), stack(right))
  })
}

// probe: this edit must be refused
