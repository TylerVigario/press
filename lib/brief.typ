// The brief template: the general-purpose document.
// A template is composed from tokens, parts and composition, and never from another template, so
// it can be read, or copied, on its own.

#import "tokens.typ": *
#import "parts.typ": *
#import "composition.typ": *

// The general-purpose document: a sheet, a guide, a brief. The title names the document once,
// in the PDF's metadata and in the head, and the footer prints it beside the status, the
// stamp and the page. `meta` sits at the right of the head; `legend` is the line under it that
// says what its colours mean: none, or the note and then the chips for the states its pages
// carry, legend: ([Colour is state.], chip([SETTLED], "ok"), chip([DECIDE], "bad")).
// `footer` is the footer (auto, footer(status:); none; or your own, footer(edition: …) for
// other words), passed here because a set page rule after the head would start a new page.
// `preset` is the page.
//
//   #show: brief.with(title: [Rack power], author: "Your name", meta: [Site A · October 2026])
#let brief(
  title: none, author: (), meta: none, status: none, legend: none, footer: auto, preset: card,
  body,
) = {
  set document(title: title, author: author)
  set page(..preset, footer: if footer == auto { _footer(status: status) } else { footer })
  set text(font: face-text, size: sz.small, fill: ink, lang: "en")
  set par(leading: 0.52em, spacing: 0.55em)
  set list(indent: 0.65em, body-indent: 0.34em, spacing: 0.32em)
  show raw: set text(font: face-mono, size: sz.fine)
  show raw.where(block: true): code
  show link: link-note

  grid(columns: (auto, 1fr), align: (left + bottom, right + bottom),
    text(font: face-display, size: sz.title, weight: 700, title),
    text(size: sz.fine, fill: ink-soft, meta))
  v(-3pt)
  line(length: 100%, stroke: 2pt + slate)
  v(4pt)
  assert(legend == none or (type(legend) == array and legend.len() > 1),
    message: "brief(legend:) takes none, its default, or the note and then its chips: "
      + "legend: ([Colour is state.], chip([DONE], \"ok\"))")
  if legend != none {
    let (note, ..chips) = legend
    grid(columns: (1fr, auto), align: (left + horizon, right + horizon),
      text(size: sz.micro, fill: ink-faint, note),
      chips.join([ #h(3pt) ]))
    v(7pt)
  }
  body
}

// brief's two layers, the act layer and then the depth layer, are brief's own, so their parts are
// too. A pointer from the act layer to the depth layer, without a page number typed by hand:
//
//   #seedepth[quarter figures]                    -> detail: quarter figures
//   #seedepth(<quarter>)                          -> detail on p. 2
//   #seedepth(at: <quarter>)[quarter figures]     -> detail: quarter figures, p. 2
//
// Given a label, the page is looked up where the label lands, so it stays right when the
// layout moves, and it links there: on a screen it clicks through, on paper it is a page
// number. A label that does not exist is a compile error, not a silent "p. ?".
#let seedepth(what, at: none, words: (detail: [detail], on: [on], page: [p.])) = {
  let w = _words("seedepth", words, "detail", "on", "page")
  let target = if type(what) == label { what } else { at }
  let on = if target != none {
    link(target, context [#w.page #counter(page).at(locate(target)).first()])
  }
  text(size: sz.fine, fill: ink-faint, style: "italic")[
    #sym.arrow.r #if type(what) == label [#w.detail #w.on #on] else if on == none [#w.detail: #what] else [#w.detail: #what, #on]
  ]
}

// Where the depth layer starts: a new page, and a line saying that what comes before it is the
// whole job, so a reader who stops there knows they have missed nothing they need. seedepth()
// points into what follows.
//
//   #depth()
#let depth(words: (note: [Nothing past this point is needed: what comes before it is the whole job.])) = {
  let w = _words("depth", words, "note")
  pagebreak(weak: true)
  text(size: sz.fine, style: "italic", fill: ink-soft, w.note)
  v(6pt)
}
