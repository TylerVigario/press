// The brief template: the general-purpose document.
// A template is composed from tokens, parts and composition, and never from another template, so
// it can be read, or copied, on its own.

#import "tokens.typ": *
#import "parts.typ": *
#import "composition.typ": *

// The general-purpose document: a sheet, a guide, a brief. The title names the document once,
// in the PDF's metadata and in the head, and the footer prints it beside the status, the
// stamp and the page. `meta` sits at the right of the head; `legend` is the colour legend
// under it: none, or one the document passes, legend(note, ..chips), for the states its pages
// carry.
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
  assert(legend != auto,
    message: "brief(legend:) takes none, its default, or a legend: legend(note, chip(...), ...)")
  if legend != none {
    legend
    v(7pt)
  }
  body
}
