// press's parts: the pieces a page is made of, each one thing, which documents and templates
// compose.

#import "tokens.typ": *

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
//   #show raw: set text(font: face-mono, size: sz.fine)
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
//
// A template installs code for every block, so a document's own rule for one block, above,
// runs first and code then meets the same block again. It marks what it holds, and leaves a
// block already inside a code alone: the document's choice stands, and the block is boxed once.
#let _in-code = state("press-in-code", false)
#let code(body, breakable: false) = context if _in-code.get() { body } else {
  block(
    width: 100%, fill: paper-tint, stroke: 0.6pt + rule-mid,
    inset: (x: 7pt, y: 6pt), radius: 1.5pt, breakable: breakable,
    { _in-code.update(true); body; _in-code.update(false) },
  )
}

// Links that work on a screen and on paper, in the one PDF. A document installs it, as it
// installs `code`:
//
//   #show link: link-note
//
// The text is coloured AND underlined, so it still reads as a link from a greyscale printer,
// and it still clicks. Where the page would hide the address, it goes in a footnote, as books
// print it: unobtrusive on a screen, and on paper the reader can still type it. The scheme
// (https://, http://, mailto:) and a trailing slash are left off, since a browser supplies
// them. No footnote when the text already is the address, or when the link goes to a place
// in the same document.
//
// Keep links out of headings once a document has an outline: the contents repeat the
// heading, and its footnote with it, so the address is noted twice.
#let link-note(it) = {
  let shown = underline(stroke: 0.5pt + slate, offset: 1.6pt, text(fill: slate, it))
  if type(it.dest) != str { return shown }
  let address = it.dest
  for prefix in ("mailto:", "https://", "http://") {
    address = address.trim(prefix, at: start, repeat: false)
  }
  address = address.trim("/", at: end, repeat: false)
  let body = if it.body.has("text") { it.body.text.trim("/", at: end, repeat: false) }
  if body in (it.dest.trim("/", at: end, repeat: false), address) { shown } else {
    shown + footnote(address)
  }
}

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

// Hairline table with a tinted header row. The header goes through `table.header`, so the
// PDF marks it as one and a screen reader reads it as the column labels, not as data.
#let matrix(head, ..rows) = table(
  columns: (auto, 1fr),
  stroke: 0.4pt + rule-hair,
  inset: (x: 7pt, y: 5.5pt),
  fill: (_, y) => if y == 0 { slate-tint } else { none },
  table.header(..head.map(h => text(size: sz.fine, weight: 700)[#h])),
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


// What only the document's owner can supply, still missing: an account number, a figure, a date.
// It prints in red and bold so it cannot go out unnoticed, and the audit counts how many remain
// ("2 open items") without failing, since a draft carries them.
//
//   Account #open[number from the statement].
#let open(body) = [#metadata("press-open")#text(fill: bad, weight: 700, body)]

// A part's own words, as a document passes them in `words`: every key the part prints must be
// there, so a misspelt or missing one is a compile error naming it, not English left behind.
#let _words(part, words, ..keys) = {
  let keys = keys.pos()
  for k in keys {
    assert(type(words) == dictionary and k in words,
      message: part + "(words:) takes " + keys.map(k => k + ":").join(", ") + "; " + k + ": is missing")
  }
  words
}

// When the page's content last changed, as tools/stamp.sh stamps it.
// A rebuild that changes nothing on the page keeps the old time, so a newer time than the
// copy on the shelf means reprint, and the same time means that copy is current. Put it in
// the footer, where every page carries it: a page parted from its stack still says which
// edition it is. Built without tools/stamp.sh -- typst watch, a bare typst compile -- there is
// no stamp, and it says so rather than inventing one.
#let updated(words: (updated: [updated], unstamped: [not stamped (built without press's stamp.sh)])) = {
  let w = _words("updated", words, "updated", "unstamped")
  let s = sys.inputs.at("press-updated", default: none)
  if s == none { w.unstamped } else { [#w.updated #s] }
}

// The footer brief prints, for a document that lays out its own page: the document's title, and
// its status where it has one, on the left; updated() and the page of the total on the right. The
// title is the one the document names itself with, set document(title:) or base's title.
// `edition` is what it says of the edition: none leaves it out, and updated(words: …) says
// it in other words.
//
//   #set page(..dense, footer: footer(status: [draft]))
#let footer(status: none, edition: updated()) = context {
  set text(size: sz.micro, fill: ink-faint)
  grid(columns: (1fr, auto),
    align(left)[#document.title#if status != none [ · #status]],
    align(right)[#if edition != none [#edition · ]#counter(page).display("1 / 1", both: true)])
}
// brief's own name for the part, since its `footer` argument hides this one inside it.
#let _footer = footer


// What the document did not set: a scanned form, an embedded PDF page, placed as it is. The
// audit leaves it out. check compiles the document a second time with every scan hidden, its
// space kept, and reads that copy for fonts, text on text and ink near the edge: a scan's own
// fonts, text layer and full-bleed ink are not findings, and whatever the document sets over
// it is audited as usual.
//
//   #place(top + left, scan(image("form.pdf", width: 100%, height: 100%)))
#let scan(body) = if sys.inputs.at("press-scans", default: none) == "hidden" { hide(body) } else { body }


// FILLING IN A FORM: a flat PDF form, or a scan of one, its blanks filled in. Each page of it is
// a form(): the blank's own page, its size and edge to edge whatever the document's preset, with
// none of the document's header, footer, background or foreground, since with no margin a header
// and a footer still print, at the paper's edges. The blank is a scan() and the answers go over
// it. at() places an answer where its blank is, measured from the page's top-left corner as a
// ruler would, and given a width a long answer wraps inside it. tick() marks a box, centred on
// the point given. The document makes the image, so its path is the document's own: a path
// handed to a part of press's is read from press's folder.
//
//   #form(image("application.pdf", page: 2))[
//     #at(72pt, 144pt)[Jane Doe]
//     #at(380pt, 144pt, width: 120pt)[an answer longer than its blank]
//     #tick(96pt, 210pt)
//   ]
#let form(blank, body) = std.page(width: auto, height: auto, margin: 0pt,
  header: none, footer: none, background: none, foreground: none,
  { block(scan(blank)); place(top + left, body) })

#let at(x, y, width: none, body) = place(top + left, dx: x, dy: y,
  if width == none { body } else { box(width: width, body) })

#let tick(x, y) = place(top + left, dx: x, dy: y,
  place(center + horizon, text(weight: 700, top-edge: "cap-height", bottom-edge: "baseline")[X]))


// The writer's name, from the document's author. Called in context; `what` names the document
// that needs it, for the message when no author is set.
#let _writer(what: "a letter") = {
  assert(document.author.len() > 0,
    message: what + " takes its writer from set document(author: \"…\"); set it once at the top")
  document.author.join(", ")
}
