// The recipe template: a recipe card.
// A template is composed from tokens, parts and composition, and never from another template, so
// it can be read, or copied, on its own.

#import "tokens.typ": *
#import "parts.typ": *

// A recipe card: the card page, a header naming the dish with its yield, method and time, and a
// line of introduction under it. The body is the cook and then the reference: the ingredients
// and the method first, then the reference, and writein() for what the cook changed. A card
// marks where its reference starts with typst's own label, <depth>, on whatever opens it, and
// recipe starts it on a page of its own under `depth`, a line saying page one is the whole cook;
// none prints no line. `footer` is the footer: none leaves it out.
//
//   #show: recipe.with(title: [Black beans], yield: [serves 8], method: [stovetop],
//     time: [about 40 min], intro: [A pot of beans for the week.])
#let recipe(
  title: none, author: (), yield: none, method: none, time: none, intro: none, preset: card,
  footer: footer(),
  depth: [Nothing past this point is needed to cook. Page 1 is the whole job.],
  body,
) = {
  set document(title: title, author: author)
  set page(..preset, footer: footer)
  set text(font: face-text, size: sz.small, fill: ink, lang: "en")
  set par(leading: 0.52em, spacing: 0.55em)
  set list(indent: 0.65em, body-indent: 0.34em, spacing: 0.32em)
  show link: link-note
  show <depth>: it => {
    pagebreak(weak: true)
    if depth != none {
      text(size: sz.fine, style: "italic", fill: ink-soft, depth)
      v(6pt)
    }
    it
  }

  header(meta: (yield, method, time).filter(x => x != none).join([ · ]))
  if intro != none {
    v(3pt)
    text(size: sz.micro, fill: ink-soft, intro)
  }
  v(7pt)
  body
}
