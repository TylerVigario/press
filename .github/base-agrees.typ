// base sets what brief sets, without brief's head, legend and footer. Each template keeps its own
// lines, so either can be read, or copied, on its own; this document is what keeps them in step.
// It reads, where each template's body starts, the page, the type, the spacing, and what the
// show rules for code and links make of a sample, and fails to compile where the two disagree.
//
//   typst compile --root . --font-path fonts --ignore-system-fonts .github/base-agrees.typ out.pdf
//
// Run by templates.sh.
#import "/lib.typ": *

#let probe(who) = context metadata((
  who: who,
  page: (page.width, page.height, page.margin, page.footer-descent),
  text: (text.font, text.size, text.fill, text.lang),
  par: (par.leading, par.spacing),
  list: (list.indent, list.body-indent, list.spacing),
  raw: measure(raw("Mx")),
  code: measure(raw("a\nb", block: true)),
  link: measure(link("https://a.example")[b]),
))

#brief(title: [Probe], legend: none, probe("brief"))
#base(title: [Probe], probe("base"))

#context {
  let seen(who) = query(metadata).find(m => type(m.value) == dictionary
    and m.value.at("who", default: none) == who).value
  let (a, b) = (seen("brief"), seen("base"))
  for k in a.keys().filter(k => k != "who") {
    assert(a.at(k) == b.at(k), message: "base and brief set " + k + " differently: "
      + repr(b.at(k)) + " against " + repr(a.at(k)))
  }
}
