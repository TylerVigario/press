// The brief template: the general-purpose document.
// A template is composed from tokens, parts and composition, and never from another template, so
// it can be read, or copied, on its own.

#import "tokens.typ": *
#import "parts.typ": *
#import "composition.typ": *

// The general-purpose document: a sheet, a guide, a brief. The title names the document once,
// in the PDF's metadata and in header(), and the footer prints it beside the status, the
// stamp and the page. `meta` sits at the right of the header; `legend` is the line under it that
// says what its colours mean: none, or the note and then the chips for the states its pages
// carry, legend: ([Colour is state.], chip([SETTLED], "ok"), chip([DECIDE], "bad")).
// `footer` is the footer (auto, footer(status:); none; or your own, footer(edition: …) for
// other words), passed here because a set page rule after the header would start a new page.
// `preset` is the page.
//
//   #show: brief.with(title: [Rack power], author: "Your name", meta: [Site A · October 2026])
//
// The act layer comes first and the depth layer after it. A document marks where its depth
// layer starts with typst's own label, <depth>, on whatever opens it, a band or a heading, and
// brief starts it on a page of its own under `depth`, a line saying nothing past it is needed;
// none prints no line. A pointer into the depth layer is typst's own page reference,
// #ref(<label>, form: "page"), which prints "page 2" and links there: brief numbers its pages
// so that typst can.
//
//   #band-strong([Reference], "reference", color: steel) <depth>
#let brief(
  title: none, author: (), meta: none, status: none, legend: none, footer: auto, preset: card,
  depth: [Nothing past this point is needed: what comes before it is the whole job.],
  body,
) = {
  set document(title: title, author: author)
  set page(..preset, numbering: "1",
    footer: if footer == auto { _footer(status: status) } else { footer })
  set text(font: face-text, size: sz.small, fill: ink, lang: "en")
  set par(leading: 0.52em, spacing: 0.55em)
  set list(indent: 0.65em, body-indent: 0.34em, spacing: 0.32em)
  show raw: set text(font: face-mono, size: sz.fine)
  show raw.where(block: true): code
  show link: link-note
  show <depth>: it => {
    pagebreak(weak: true)
    if depth != none {
      text(size: sz.fine, style: "italic", fill: ink-soft, depth)
      v(6pt)
    }
    it
  }

  header(meta: meta)
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
