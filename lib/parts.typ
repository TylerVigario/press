// press's parts: the pieces a page is made of, each one thing, which documents and templates
// compose.

#import "tokens.typ": *

// `caps` is opt-out because upper() CORRUPTS case-carrying strings, and silently:
// "pH" becomes "PH", "iOS" becomes "IOS", and "µS" becomes "ΜS" — micro-sign
// turned into capital Mu, a different character entirely. Pass `caps: false`
// whenever the case of the label means something.
#let eyebrow(body, color: slate, caps: true, size: sz.fine) = text(
  size: size, weight: 700, tracking: 1.2pt, fill: color,
  if caps { upper(body) } else { body },
)

// A section whose headings show its state: inside it, a template's `=` band and `==` label take
// `color`, any colour, where every other heading stays slate. Where it is ok, warn or bad, they
// draw that state's shape too, as a chip does, so the state reads on a grey printout. Wrap the
// one heading or the whole section. A label on the heading, `<depth>` among them, stays where it
// is; a section inside another takes its own colour; `#show: section.with(color: steel)` colours
// a whole document's.
//
//   #section(color: bad)[= Red-flag signs]
#let _section-colors = state("press-section-colors", ())
#let section(body, color: slate) = {
  _section-colors.update(s => s + (color,))
  body
  _section-colors.update(s => s.slice(0, -1))
}
// The colour of a heading where it stands, which a template's heading rules read in context.
#let _section-color() = _section-colors.get().at(-1, default: slate)

// The gap between a part's pieces: its label, title or lead and its body. Each part sets it for
// itself, so a part keeps the layout it was drawn for whatever gap a template sets between a
// document's paragraphs; the body's own paragraphs and lists keep the document's, as _body sets.
#let _part-gap = 0.55em

// A part's body, its paragraphs and lists spaced as the document spaces them: `spacing` is the
// document's paragraph spacing, read before the part sets its own. The part's own gap stays around
// the body, so a body of one paragraph sits as it did, and the part's other pieces with it. The
// body is as wide as the part: typst aligns a thing within the block it is in, so a flow in a body
// only as wide as its widest line would centre on that line, not on the part.
#let _body(spacing, body) = block(width: 100%, spacing: _part-gap, {
  set par(spacing: spacing)
  body
})

// press's marks in a title, unsourced()'s, and the title without them. footer() prints the title
// on every page, and a mark printed with it each time would count one item once a page.
#let _is-mark(it) = (type(it) == content and it.func() == metadata and type(it.value) == str
  and it.value.starts-with("press-"))
#let _marks(it) = {
  if type(it) != content { () } else if _is-mark(it) { (it,) }
  else if it.has("children") { it.children.map(_marks).flatten() } else { () }
}
#let _unmarked(it) = {
  if type(it) != content { it } else if _is-mark(it) { none }
  else if it.has("children") { it.children.map(_unmarked).join() } else { it }
}

// A title marked with unsourced() is counted once, wherever it prints, and where it prints
// nowhere, as a letter's: typst's title() with the document's own title counts it, printing it;
// else header(); else the footer() on the first page that has one; else the start of the
// document, which every template marks. The others print it without its marks.
#let _titled() = query(title).any(t => t.body == auto or t.body == document.title)

// The start of a template's document, where the title is counted when nothing prints it.
#let _title-start() = context if (not _titled() and query(<press-header>).len() == 0
  and query(<press-footer>).len() == 0) {
  _marks(document.title).join()
}

// A calibration as a template takes it, checked, each number it leaves out taken from press's
// own, `calibration` in tokens.typ. An edge's band and a rule's width are absolute lengths; ink
// and fill are contrasts on white, from 1 to 21, 6 for 6:1.
#let _calibration(given) = {
  assert(type(given) == dictionary, message: "calibration takes a dictionary, (edges: (…), "
    + "ink: …, fill: …, rule: (…)); got " + repr(given))
  for key in given.keys() {
    assert(key in calibration, message: "calibration takes " + calibration.keys().join(", ")
      + "; got " + key)
  }
  let readings = (ink: "the lightest text ink that reads", fill: "the palest fill that prints even")
  for (key, what) in readings {
    let v = given.at(key, default: calibration.at(key))
    assert(type(v) in (int, float) and v >= 1 and v <= 21, message: "calibration's " + key
      + " takes " + what + ", as its contrast on white, from 1 to 21, 6 for 6:1; got " + repr(v))
  }
  let rule = given.at("rule", default: (:))
  assert(type(rule) == dictionary, message: "calibration's rule takes a dictionary, (rule-hair: …, "
    + "rule-mid: …, slate: …, ink: …); got " + repr(rule))
  for (name, width) in rule {
    assert(name in calibration.rule,
      message: "calibration's rule takes rule-hair, rule-mid, slate and ink; got " + name)
    assert(type(width) == length and width.em == 0 and width >= 0pt, message: "calibration's rule "
      + "takes for " + name + " an absolute length, the thinnest rule that prints unbroken; got "
      + repr(width))
  }
  let edges = given.at("edges", default: (:))
  assert(type(edges) == dictionary, message: "calibration's edges takes a dictionary, (top: …, "
    + "bottom: …, left: …, right: …); got " + repr(edges))
  for (edge, band) in edges {
    assert(edge in calibration.edges,
      message: "calibration's edges are top, bottom, left and right; got " + edge)
    assert(type(band) == length and band.em == 0 and band >= 0pt, message: "calibration's " + edge
      + " edge takes an absolute length, the band the printer cannot print; got " + repr(band))
  }
  (
    edges: calibration.edges + edges,
    ink: float(given.at("ink", default: calibration.ink)),
    fill: float(given.at("fill", default: calibration.fill)),
    rule: calibration.rule + rule,
  )
}

// A preset set for a calibration: each margin widened by as much as the calibration's band at
// that edge exceeds press's own, which every preset's ink, its header and footer included,
// already clears. A header and a footer keep their distance from the body, so each moves with
// its margin and clears the band too. A band no wider than press's changes nothing.
#let _page(preset, given) = {
  let edges = _calibration(given).edges
  let more = (:)
  for (edge, band) in edges { more.insert(edge, calc.max(0pt, band - calibration.edges.at(edge))) }
  if more.values().all(m => m == 0pt) { return preset }
  let m = preset.at("margin", default: auto)
  let given-as(edge, ..others) = {
    let v = if type(m) == dictionary {
      let found = (edge, ..others.pos(), "rest").filter(k => k in m)
      if found.len() > 0 { m.at(found.first()) } else { auto }
    } else { m }
    assert(type(v) == length, message: "calibration widens a page's margins, so its " + edge
      + " margin must be a length; got " + repr(v))
    v
  }
  // A header's ascent and a footer's descent, typst's 30% of their margin unless given, are
  // fixed at what they were, so a wider margin does not move them further into it.
  let fixed(v, margin) = if type(v) == ratio { v * margin }
    else if type(v) == relative { v.ratio * margin + v.length } else { v }
  let (top, bottom) = (given-as("top", "y"), given-as("bottom", "y"))
  let sides = if type(m) == dictionary and ("inside" in m or "outside" in m) {
    let wider = calc.max(more.left, more.right)
    (inside: given-as("inside", "x") + wider, outside: given-as("outside", "x") + wider)
  } else {
    (left: given-as("left", "x") + more.left, right: given-as("right", "x") + more.right)
  }
  (
    ..preset,
    margin: (top: top + more.top, bottom: bottom + more.bottom, ..sides),
    header-ascent: fixed(preset.at("header-ascent", default: 30%), top),
    footer-descent: fixed(preset.at("footer-descent", default: 30%), bottom),
  )
}

// The calibration's bands, for the audit, in inches, top, bottom, left and right: it fails ink
// nearer an edge than that edge's band. A template places it where it starts.
#let _edges-mark(given) = {
  let edges = _calibration(given).edges
  metadata("press-edges " + ("top", "bottom", "left", "right")
    .map(edge => str(calc.round(edges.at(edge) / 1in, digits: 4))).join(" "))
}

// A colour darkened to the lightest shade whose contrast on white reaches `ratio`, by scaling its
// light, each of its channels in linear light by one factor: the same colour in less light, its
// hue kept, and never outside what a printer's sRGB holds. A colour that reaches `ratio` already
// is returned as it is.
#let _darken-to(colour, ratio) = {
  if _contrast(colour) >= ratio { return colour }
  let light = rgb(colour).components(alpha: false).map(c => _linear(c / 100%))
  let y = 0.2126 * light.at(0) + 0.7152 * light.at(1) + 0.0722 * light.at(2)
  // A hair under the factor that meets `ratio` exactly, so rounding never leaves it short.
  let k = 0.9999 * (1.05 / ratio - 0.05) / y
  let encode(v) = if v <= 0.0031308 { 12.92 * v } else { 1.055 * calc.pow(v, 1 / 2.4) - 0.055 }
  rgb(..light.map(v => encode(k * v) * 100%))
}

// press's presets, set for a calibration, by name: each of press's inks darkened to the
// calibration's `ink`, each tint to its `fill`, `rule` the thinnest rule in each rule colour, and
// the page presets, `dense`, `reading` and `card`, their margins widened for its `edges`. press's
// functions take them from the calibration their template was given; a document takes them here
// for what it draws itself:
//
//   #let c = calibrated(calibration)
//   #text(fill: c.ink-faint)[…]  #line(stroke: c.rule.rule-hair + rule-hair)  #set page(..c.card)
#let calibrated(given) = {
  let set-for = _calibration(given)
  let presets = (:)
  for (name, colour) in _inks { presets.insert(name, _darken-to(colour, set-for.ink)) }
  for (name, colour) in _tints { presets.insert(name, _darken-to(colour, set-for.fill)) }
  presets.insert("rule", set-for.rule)
  for (name, preset) in (dense: dense, reading: reading, card: card) {
    presets.insert(name, _page(preset, given))
  }
  presets
}

// The calibration a document's template was given, which press's functions read in context: a
// document has one, so each reads the last.
#let _calibration-state = state("press-calibration", (:))
#let _presets() = calibrated(_calibration-state.final())

// A colour as press's functions draw it: one of press's inks or tints, set for the document's
// calibration, and any other as it is. _cal is called in context; _cal-in takes the presets, as a
// template that holds its calibration does.
#let _cal-in(presets, colour) = {
  for (name, own) in _inks + _tints { if colour == own { return presets.at(name) } }
  colour
}
#let _cal(colour) = _cal-in(_presets(), colour)

// A stroke of `width` in `colour`, as press's functions draw it: the colour set as _cal sets it,
// at least as wide as the calibration's thinnest rule in the darkest of press's rule colours no
// darker than it, or in rule-hair where it is paler than all of them. _stroke is called in
// context, and _stroke-in takes the presets, as _cal-in does.
#let _stroke-in(presets, width, colour) = {
  let colour = _cal-in(presets, colour)
  let under = _rules.pairs().filter(((_, c)) => _contrast(c) <= _contrast(colour))
    .sorted(key: ((_, c)) => _contrast(c))
  let floor = presets.rule.at(if under.len() > 0 { under.last().at(0) } else { "rule-hair" })
  calc.max(width, floor) + colour
}
#let _stroke(width, colour) = _stroke-in(_presets(), width, colour)

// A template's calibration, applied to all it sets: its bands recorded for the audit, the
// calibration for press's functions, and each of press's inks it darkens set in that ink as the
// calibration darkens it. An ink is set where its text is, so a document's own text in one of
// press's inks, `text(fill: ink-faint)`, is darkened with press's; so is what stands in such text
// without being a text of its own, a curled quote or an equation.
#let _calibrate(given, body) = {
  let presets = calibrated(given)
  let changed = _inks.pairs().filter(((name, own)) => presets.at(name) != own)
  let shade(fill) = {
    let found = changed.find(((_, own)) => fill == own)
    if found == none { fill } else { presets.at(found.at(0)) }
  }
  let in-shade(it) = context {
    let fill = shade(text.fill)
    if fill == text.fill { it } else { text(fill: fill, it) }
  }
  [#_edges-mark(given)#_calibration-state.update(_calibration(given))]
  // typst's own footnote rule, black and 0.5pt, drawn as press draws a rule in that colour.
  set footnote.entry(separator: line(length: 30% + 0pt, stroke: _stroke-in(presets, 0.5pt, black)))
  if changed.len() == 0 { body } else {
    show smartquote: in-shade
    show math.equation: in-shade
    changed.fold(body,
      (it, (name, own)) => { show text.where(fill: own): set text(fill: presets.at(name)); it })
  }
}

// A document's header: its title on the left, `meta` on the right, and a rule beneath. The title
// is the one the document names itself with, set document(title:) or a template's title, so it
// is named once, as footer() names it. A title that fits on one line keeps it, and `meta` wraps
// beside it. Beside a title too long for one line, `meta` keeps its one line where it fits in
// half the line, and else the two share the line in halves.
//
//   #header(meta: [Site A · October 2026])
#let header(meta: none, color: slate, face: face-display, size: sz.title) = context block(width: 100%, {
  // Its rule sits under the title by the part's own gap, whatever a template sets between
  // paragraphs.
  set par(spacing: _part-gap)
  // Tells footer() and the document's start the title's marks are counted here.
  [#metadata(none)<press-header>]
  if not _titled() { _marks(document.title).join() }
  layout(region => {
    let title = text(font: face, size: size, weight: 700, fill: ink, _unmarked(document.title))
    let note = text(size: sz.fine, fill: ink-soft, meta)
    let gap = 9pt
    let half = (region.width - gap) / 2
    grid(
      columns: if measure(title).width + gap < region.width { (auto, 1fr) }
        else if measure(note).width <= half { (1fr, auto) } else { (1fr, 1fr) },
      column-gutter: gap,
      align: (left + bottom, right + bottom),
      title, note,
    )
  })
  // The rule clears the title's descenders: it sits as far under the face's descender line as the
  // gap alone would put it under the baseline, and what follows moves down with it.
  let depth = measure(text(font: face, size: size, weight: 700, top-edge: "baseline",
    bottom-edge: "descender")[g]).height
  v(-3pt + depth)
  line(length: 100%, stroke: _stroke(2pt, color))
})

#let tones = (
  note: (slate, slate-tint), ok: (ok, ok-tint),
  warn: (warn, warn-tint), bad: (bad, bad-tint),
)

// The shape each tone draws beside a state, so the state reads without its colour. Printed in
// grey, ok and warn come out nearly the same, about 96 and 102 of 255 in Rec. 601 luma, and on
// paper colour alone carries nothing that a monochrome printer or a reader's eyes may lose.
#let _tone-shapes = (note: "diamond", ok: "circle", warn: "triangle", bad: "square")

// The shape a template's headings draw where the section's colour is a state's, ok, warn or bad,
// and none for any other: slate is every heading's colour, so note's diamond would mark them all.
#let _section-shape() = {
  let c = _section-color()
  let tone = tones.keys().find(t => t != "note" and tones.at(t).at(0) == c)
  if tone == none { none } else { _tone-shapes.at(tone) }
}

// A shape filled with `color`, about as tall as a capital, centred on the capitals of the text it
// sits in, as checkbox() centres on the lowercase. Each is drawn to look the same size as the
// others, so a square is a little smaller than a circle and a triangle a little wider.
#let _shape(name, color) = context {
  let color = _cal(color)
  let cap = measure(text(top-edge: "cap-height", bottom-edge: "baseline")[X]).height
  let s = 0.85 * cap
  let drawn = if name == "circle" { circle(radius: s / 2, fill: color) }
    else if name == "square" { square(size: 0.88 * s, fill: color) }
    else if name == "triangle" { polygon(fill: color, (0pt, s), (0.6 * s, 0pt), (1.2 * s, s)) }
    else { polygon(fill: color, (0.6 * s, 0pt), (1.2 * s, 0.6 * s), (0.6 * s, 1.2 * s), (0pt, 0.6 * s)) }
  let h = measure(drawn).height
  box(baseline: h / 2 - cap / 2, drawn)
}

// A state's shape and a space, set before a part's label in the tone's colour: the tone's own
// shape where `shape` is auto, another of the four by name, or nothing where it is none.
#let _shaped(part, tone, shape, gap: 0.35em) = {
  let shape = if shape == auto { _tone-shapes.at(tone) } else { shape }
  assert(shape == none or shape in _tone-shapes.values(),
    message: part + "(shape:) expects \"circle\", \"triangle\", \"square\", \"diamond\" or "
      + "none; got " + repr(shape))
  if shape != none [#_shape(shape, tones.at(tone).at(0))#h(gap)]
}

// Tinted callout with a weighted left edge. Its label is kept with the body under it, so a page
// never ends on the label alone. The label's block is set at the label's own size, as a line of
// it would be, so the space under it is measured in that size and not the callout's. Its tone's
// shape goes before its label, or before its body where it has none, so its state reads on a
// grey printout as a chip's does; `shape` changes it, as chip(shape:) does. `caps: false` keeps
// its label's case.
#let callout(body, tone: "note", label: none, size: sz.small, shape: auto, caps: true) = {
  let pair = tones.at(tone)
  let mark = _shaped("callout", tone, shape)
  context block(
    width: 100%, fill: _cal(pair.at(1)), stroke: (left: _stroke(3pt, pair.at(0))),
    inset: (x: 10pt, y: 8pt),
  )[
    #let spacing = par.spacing
    #set par(spacing: _part-gap)
    #if label != none [#text(size: sz.fine, block(sticky: true,
      [#mark#eyebrow(label, color: pair.at(0), caps: caps)])) #v(3pt)]
    #text(size: size, _body(spacing, [#if label == none { mark }#body]))
  ]
}

// Bordered panel — for grids where a tint would shout. Its label is kept with the body, as a
// callout's is, and `caps: false` keeps its case.
#let panel(body, label: none, color: slate, caps: true) = context block(
  width: 100%, stroke: _stroke(0.6pt, rule-mid), inset: 10pt, radius: 1pt,
)[
  #let spacing = par.spacing
  #set par(spacing: _part-gap)
  #if label != none [#text(size: sz.fine, block(sticky: true, eyebrow(label, color: color, caps: caps))) #v(4pt)]
  #_body(spacing, body)
]

// Code block treatment. Every template installs it, and a document without one installs it:
//
//   #show raw: set text(font: face-mono, size: sz.fine / sz.small / 0.8 * 1em)
//   #show raw.where(block: true): code
//
// The first sets code a step below the text around it, sz.fine in body text: typst's own rule
// for raw sets it at 0.8em, and an em in a rule for raw is that 0.8em.
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
// A block is kept whole wherever it fits on a page. A command split across a page
// turn is a command with no second half, so by default a block that falls across one
// starts the next page whole; only a block taller than a page breaks, since kept whole
// it would run off the page's foot and its end print on no page. A long listing that
// should break at any turn passes `breakable: true` through a closure:
//
//   #show raw.where(block: true): it => code(it, breakable: true)
//
// and `breakable: false` keeps every block whole, one taller than a page too.
//
// _fit(part, breakable, made): the block `made(breakable)` gives, where breakable is auto
// kept whole where it fits on a page and let break where it is taller than one, as a sheet's
// row is. A page's height is the height of the region it is laid out in; measured, as inside
// units(), the page has no end, and the block is kept whole. true and false are passed as they
// are.
#let _fit(part, breakable, made) = {
  assert(breakable in (auto, true, false),
    message: part + "(breakable:) takes auto, true or false; got " + repr(breakable))
  if breakable != auto { made(breakable) } else {
    layout(region => made(measure(block(width: region.width, made(false))).height > region.height))
  }
}
// A template installs code for every block, so a document's own rule for one block, above,
// runs first and code then meets the same block again. It marks what it holds, and leaves a
// block already inside a code alone: the document's choice stands, and the block is boxed once.
#let _in-code = state("press-in-code", false)
// A line wider than its block wraps: it copies with a break in it, and on paper it reads as two
// lines. Each one leaves a mark, which check fails on: its page and how it starts. Placed, so the
// measuring takes no room on the page.
#let _wraps(body) = if body.func() == raw {
  place(layout(size => for l in body.lines {
    if measure(l).width > size.width {
      let start = l.text.replace(regex("[\\s\"\\\\]+"), " ").trim()
      let cs = start.clusters()
      let start = if cs.len() > 40 { cs.slice(0, 40).join() + "…" } else { start }
      [#metadata("press-code-wrap " + str(here().page()) + " " + start)]
    }
  }))
}
#let code(body, breakable: auto) = context if _in-code.get() { body } else {
  _fit("code", breakable, b => block(
    width: 100%, fill: _cal(paper-tint), stroke: _stroke(0.6pt, rule-mid),
    inset: (x: 7pt, y: 6pt), radius: 1.5pt, breakable: b,
    { _in-code.update(true); _wraps(body); body; _in-code.update(false) },
  ))
}

// A piece of text with a straight quote in it, its quotes made smart, so typst curls each as it
// does one typed in markup; a piece with none is shown as it is. Every template shows its text
// with it. A quote typed in markup is a smart quote already and never reaches it, so it turns
// only a string's quotes, and an escaped one's. It rebuilds the whole piece, never the quote
// alone: what a show rule puts in is set apart from the text around it, and a rule on the quote
// would lose the kerning on either side of it.
#let _curl(it) = {
  if not ("'" in it.text or "\"" in it.text) { return it }
  let parts = ()
  let run = ""
  for c in it.text.clusters() {
    if c in ("'", "\"") {
      parts.push(run)
      run = ""
      parts.push(smartquote(double: c == "\""))
    } else { run += c }
  }
  parts.push(run)
  parts.join()
}

// Links that work on a screen and on paper, in the one PDF. Every template installs it, as it
// installs `code`, and a document without one installs it:
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
  let shown = context underline(stroke: _stroke(0.5pt, slate), offset: 1.6pt, text(fill: slate, it))
  if type(it.dest) != str { return shown }
  let address = it.dest
  for prefix in ("mailto:", "https://", "http://") {
    address = address.trim(prefix, at: start, repeat: false)
  }
  address = address.trim("/", at: end, repeat: false)
  let body = if it.body.has("text") { it.body.text.trim("/", at: end, repeat: false) }
  // An address keeps its quotes straight where it prints, so it works when copied.
  let straight(address) = { set smartquote(enabled: false); address }
  if body in (it.dest.trim("/", at: end, repeat: false), address) { straight(shown) } else {
    shown + footnote(straight(address))
  }
}

// Numbered entry: marker, title, explanation. Kept whole where it fits on a page, and let break
// where it is taller than one; `breakable` is as code()'s.
#let item(n, title, body, color: slate, size: sz.small, breakable: auto) = context _fit("item",
  breakable, b => block(width: 100%, breakable: b, inset: (bottom: 6pt))[
  #let spacing = par.spacing
  #set par(spacing: _part-gap)
  #text(size: size, weight: 700, fill: color)[#n]
  #h(5pt)
  #text(size: size, weight: 700)[#title]
  #v(2pt)
  #text(size: size, _body(spacing, body))
])

// a → b → c, for pipelines.
#let flow(..steps) = align(center)[
  #context box(inset: (x: 9pt, y: 6pt), stroke: _stroke(0.6pt, rule-mid), radius: 1pt)[
    #text(size: sz.small)[
      #steps.pos().join([ #text(fill: ink-faint)[#sym.arrow.r] ])
    ]
  ]
]

#let stamp(body) = {
  // The hairline is a sticky block, which typst keeps with the words after it, so a page never
  // ends on the rule alone. The gap under it is the part's own, as inside every other part.
  block(sticky: true, below: _part-gap, {
    v(4pt)
    context line(length: 100%, stroke: _stroke(0.5pt, rule-hair))
    v(2pt)
  })
  text(size: sz.micro, fill: ink-faint, style: "italic")[#body]
}

// A note set under an entry later, beside what it amends rather than over it: a revisit, a
// retelling, a correction to a record that keeps what was first written. Its label and date stay
// on the page with its body, so a page never ends on them alone. `label` says what kind of note
// it is, `color` draws its edge and label, and `caps: false` keeps its case. Its label is
// sz.fine, or the size of the text around it where that is smaller, as in a sheet's cell, so it
// never outweighs the entry it is under.
//
//   #addendum([2026-10-15 21:11], label: [Retold])[What was told the second time.]
#let addendum(date, body, label: [Later], color: ink-faint, caps: true) = context block(
  width: 100%, above: 0.9em, inset: (left: 0.8em), stroke: (left: _stroke(0.6pt, color)),
)[
  #let spacing = par.spacing
  #set par(spacing: _part-gap)
  #block(sticky: true, below: 0.75em, context eyebrow([#label · #date], color: color, caps: caps,
    size: calc.min(sz.fine, text.size)))
  #text(fill: ink-soft, _body(spacing, body))
]

// The sources a document cites by number, and the numbered list of them where they close it. A
// source is given once, in `sources()`, by its key, its title and its address, and numbered in
// the order given, across the document: a second list's numbers go on from the first's, so a
// marker's number is the one its source prints with, wherever the list is. `src()` prints the
// numbers of the keys it names, small and faint, so a sentence reads past them. A key no
// `sources()` gives, or one given twice, in one list or in two, is a compile error naming it.
// The list prints at `size`, `across` columns `gutter` apart, a source to a line: its number,
// its title and its address, printed without `https://` so it reads and types from paper, while
// its link holds it whole. An address of `none` prints the title alone.
//
//   Most of the county's wells were tested in the spring #src("wells", "survey").
//
//   #sources(
//     ("wells", [Sam Example, Well testing in the county, 2025], "https://example.org/wells/2025"),
//     ("survey", [County Water District, Groundwater survey, 2026], none),
//   )
#let src(..keys) = context {
  let keys = keys.pos()
  assert(keys.len() > 0, message: "src() needs the key of a source")
  let given = query(<press-source>).map(m => m.value)
  let ns = keys.map(k => {
    let i = given.position(g => g == k)
    assert(i != none, message: "src(): no sources() gives the key " + repr(k))
    i + 1
  }).dedup().sorted()
  text(size: sz.micro, fill: ink-faint)[[#ns.map(str).join(", ")]]
}

#let sources(..entries, size: sz.micro, across: 2, gutter: 10pt) = {
  let entries = entries.pos()
  for e in entries {
    assert(type(e) == array and e.len() == 3 and type(e.at(0)) == str,
      message: "sources() takes each source as (key, title, address); got " + repr(e))
  }
  let keys = entries.map(e => e.at(0))
  for k in keys { [#metadata(k)<press-source>] }
  // Each key is given once in the document, so the first's place among every list's keys is
  // how many sources come before this list's.
  context {
    let given = query(<press-source>).map(m => m.value)
    for k in keys {
      assert(given.filter(x => x == k).len() == 1, message: "sources(): the key " + repr(k)
        + " is given twice")
    }
    let before = if keys.len() > 0 { given.position(g => g == keys.first()) } else { 0 }
    set text(size: size)
    let lines = for (i, (_, title, url)) in entries.enumerate() {
      [#(before + i + 1). #title#if url != none [
        · #link(url)[#url.trim("https://", at: start)]] \ ]
    }
    if across == 1 { lines } else { columns(across, gutter: gutter, lines) }
  }
}


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

// A value the document prints without having read it from a source, marked by its `kind`, so that
// on paper it never reads like the values around it that were:
//
//   "open"      what only the document's owner can supply, left to fill in: an account number, a
//               figure, a date. Red and bold, so it cannot go out unnoticed.
//   "missing"   what the document does not have and no one will supply, printed where it would
//               stand, since a blank there reads as none. Faint and italic, apart from the values
//               around it.
//   "estimate"  a figure printed but guessed: a price estimated for a category, a size judged by
//               eye. The figure, then a word that says so, both in amber and bold: the colour is
//               lost on a grey printout, and the word is not.
//
// The kind is what the audit reads. It says how many open items remain ("2 open items") and how
// many estimates a document prints, and fails for neither, since a draft carries them; a missing
// value it leaves alone, as nothing is left to do. How each kind looks is only its default:
// `color`, `weight` and `style` change it, and `words` the word an estimate prints.
//
//   Account #unsourced[number from the statement].
//   Milkings per day: #unsourced(kind: "missing")[not recorded].
//   Feed, per bag: #unsourced(kind: "estimate")[\$18.00].
//
// A document that marks one kind often names it once:
//
//   #let est = unsourced.with(kind: "estimate")
#let _unsourced = (
  open: (fill: bad, weight: 700),
  missing: (fill: ink-faint, style: "italic"),
  estimate: (fill: warn, weight: 700),
)
#let unsourced(
  body, kind: "open", color: auto, weight: auto, style: auto, words: (estimate: [estimate]),
) = {
  // An unknown kind fails rather than falling through to one that looks deliberate.
  assert(type(kind) == str and kind in _unsourced,
    message: "unsourced(kind:) expects \"open\", \"missing\" or \"estimate\"; got " + repr(kind))
  let word = _words("unsourced", words, "estimate").estimate
  let look = _unsourced.at(kind)
  for (key, value) in (fill: color, weight: weight, style: style) {
    if value != auto { look.insert(key, value) }
  }
  [#metadata("press-" + kind)#text(..look, if kind == "estimate" [#body #word] else { body })]
}

// A number with its whole part grouped by thousands, from four digits, so a figure read at a
// glance is not misread: 3465 prints 3,465, and decimal("1234567.50") prints 1,234,567.50. Its
// decimals stay as typst prints them, and so does its sign, typst's minus. It takes an int, a
// float or a decimal; a figure read from data as text is converted first, `num(int(row.cows))`.
// A sum of money is a decimal, `num(decimal(row.amount))`: typst prints a float in its shortest
// form, so 12480.50 read as a float prints 12,480.5, and a sum of floats can print
// 0.30000000000000004, where a decimal keeps its places through arithmetic. In TOML or JSON,
// where a number with cents is a float, write the sum as a string. A figure is kept whole, so a
// line never breaks inside it and a reader never sees two numbers. A thin space groups it
// instead, as NIST SP 811 groups digits: `words: (thousands: [#sym.space.thin])`.
//
//   #sheet((1fr, auto), ([Dairy], [Cows]), [North], num(3465), [South], num(12480))
#let num(n, words: (thousands: [,])) = {
  assert(type(n) in (int, float, decimal),
    message: "num() takes an int, a float or a decimal; got " + repr(n))
  let sep = _words("num", words, "thousands").thousands
  let s = str(n)
  let sign = if s.starts-with("\u{2212}") { "\u{2212}" } else { "" }
  let (whole, ..decimals) = s.slice(sign.len()).split(".")
  assert(whole.match(regex("^[0-9]+$")) != none,
    message: "num() groups the digits typst prints, and it prints " + s)
  let digits = whole.clusters()
  let groups = ()
  let end = digits.len()
  while end > 0 {
    groups.insert(0, digits.slice(calc.max(0, end - 3), end).join())
    end -= 3
  }
  box[#sign#groups.join(sep)#if decimals.len() > 0 [.#decimals.join()]]
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

// A page's footer, so a page parted from the rest still says what it is and which edition: the
// document's title, and its status where it has one, on the left; updated() and the page of the
// total on the right. The title is the one the document names itself with, set document(title:)
// or a template's title, as header() names it. `edition` is what it says of the edition: none
// leaves it out, and updated(words: …) says it in other words. A title marked with unsourced()
// counts once: typst's title() with the document's own title counts it, or header(), or with
// neither, the footer on the first page that has one. A status marked with it counts once too,
// on the first page with a footer; the pages after print it without its marks.
//
//   #set page(..dense, footer: footer(status: [draft]))
#let footer(status: none, edition: updated()) = context {
  set text(size: sz.micro, fill: _cal(ink-faint))
  // Tells the document's start, and the footers after this one, the title's marks are counted.
  [#metadata(none)<press-footer>]
  let footers = query(<press-footer>)
  let first = footers.len() > 0 and footers.first().location().page() == here().page()
  if first and query(<press-header>).len() == 0 and not _titled() {
    _marks(document.title).join()
  }
  grid(columns: (1fr, auto),
    align(left)[#_unmarked(document.title)#if status != none [ · #if first { status } else { _unmarked(status) }]],
    align(right)[#if edition != none [#edition · ]#counter(page).display("1 / 1", both: true)])
}


// What the document did not set: a scanned form, an embedded PDF page, placed as it is. The
// audit leaves it out. check compiles the document a second time with every scan hidden, its
// space kept, and reads that copy for fonts, text on text and ink near the edge: a scan's own
// fonts, text layer and full-bleed ink are not findings, and whatever the document sets over
// it is audited as usual.
//
//   #place(top + left, scan(image("form.pdf", width: 100%, height: 100%)))
#let scan(body) = if sys.inputs.at("press-scans", default: none) == "hidden" { hide(body) } else { body }


// The measuring grid form(probe:) draws over its page, for reading where each blank is: a line
// every step, every fourth one heavier, and where two heavy lines cross, that point's x and y in
// points, as place() takes them. In the blue a layout guide is drawn in, over the blank and the
// answers both, so an answer can be checked against its blank. It is a scan(), so the audit
// leaves it out, and the audit fails while it is on.
#let _probe(step) = place(top + left, layout(size => {
  let step = step.to-absolute()
  assert(step > 0pt, message: "form(probe:) takes a step greater than zero: probe: 18pt")
  let guide = rgb("#4aa8d8")
  let (nx, ny) = (int(size.width / step), int(size.height / step))
  for i in range(nx + 1) {
    place(top + left, dx: i * step, line(angle: 90deg, length: size.height,
      stroke: if calc.rem(i, 4) == 0 { 0.6pt + guide } else { 0.3pt + guide.transparentize(50%) }))
  }
  for j in range(ny + 1) {
    place(top + left, dy: j * step, line(length: size.width,
      stroke: if calc.rem(j, 4) == 0 { 0.6pt + guide } else { 0.3pt + guide.transparentize(50%) }))
  }
  let pt(v) = str(calc.round(v.pt(), digits: 2))
  for i in range(0, nx + 1, step: 4) {
    for j in range(0, ny + 1, step: 4) {
      place(top + left, dx: i * step + 1pt, dy: j * step + 1pt,
        text(font: face-mono, size: 5pt, fill: guide.darken(40%), [#pt(i * step), #pt(j * step)]))
    }
  }
}))

// FILLING IN A FORM: a flat PDF form, or a scan of one, its blanks filled in. Each page of it is
// a form(): the blank's own page, its size and edge to edge whatever the document's preset, with
// none of the document's header, footer, background or foreground, since with no margin a header
// and a footer still print, at the paper's edges. The blank is a scan() and the answers go over
// it. An answer is typst's own place(dx:, dy:), measured from the page's top-left corner as a
// ruler would: the point is the answer's own top-left, where its capitals begin, so the text
// hangs below it, and an answer meant to stand on a blank's line goes above the line by its
// capitals' height, about seven tenths of its text size. In a box with a width, a long answer
// wraps inside it. tick() marks a box, centred on the point given. The document makes the image,
// so its path is the document's own: a path handed to a part of press's is read from press's
// folder. Given probe: and a step, form() draws a measuring grid over its page for reading where
// each blank is, and the audit fails while it is on.
//
//   #form(image("application.pdf", page: 2))[
//     #place(dx: 72pt, dy: 144pt)[Jane Doe]
//     #place(dx: 380pt, dy: 144pt, box(width: 120pt)[an answer longer than its blank])
//     #tick(96pt, 210pt)
//   ]
#let form(blank, probe: none, body) = {
  assert(probe == none or type(probe) == length,
    message: "form(probe:) takes none, its default, or the grid's step as a length: probe: 18pt")
  std.page(width: auto, height: auto, margin: 0pt,
    header: none, footer: none, background: none,
    foreground: if probe != none { scan(_probe(probe)) },
    { block(scan(blank)); place(top + left, body); if probe != none { metadata("press-probe") } })
}

#let tick(x, y) = place(top + left, dx: x, dy: y,
  place(center + horizon, text(weight: 700, top-edge: "cap-height", bottom-edge: "baseline")[X]))


// The writer's name, from the document's author. Called in context; `what` names the document
// that needs it, for the message when no author is set.
#let _writer(what: "a letter") = {
  assert(document.author.len() > 0,
    message: what + " takes its writer from set document(author: \"…\"); set it once at the top")
  document.author.join(", ")
}
