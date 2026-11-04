// Paragraphs and lists under the template `--input template=` names, for list-spacing.sh: a
// paragraph of two lines and the next, then a bulleted list, a numbered one and a checklist whose
// first item has a second line, a paragraph after the lists, and a unit and an item.
#import "/lib.typ": *

#let template = (brief: brief, base: base, recipe: recipe, resume: resume, letter: letter).at(
  sys.inputs.at("template", default: "brief"))
#show: template.with(title: [Probe], author: "press")

Paraone opens a paragraph \ Paraline continues it

Paratwo is the next paragraph

- Bulletone opens the item \ Bulletline continues it
- Bullettwo is the next item

+ Enumone opens the item \ Enumline continues it
+ Enumtwo is the next item

#[
  #set list(marker: checkbox(), body-indent: 0.6em)
  - Checkone opens the item \ Checkline continues it
  - Checktwo is the next item
]

Paraafter follows the lists

#unit([Unitlabel], "note", caps: false)[Unitlead holds.][Unitbody under it.]
#item(1, [Itemtitle of a step], [Itembody under it.])

// Inside each part whose body a document writes, the same: two paragraphs, a list whose first item
// has a second line, and a paragraph after it, its words beginning with the part's name. Each
// part has a page of its own, so none breaks across one under a template's larger type.
#let prose(p) = [
  #(p + "one") opens a paragraph \ #(p + "line") continues it

  #(p + "two") is the next paragraph

  - #(p + "bone") opens the item \ #(p + "bline") continues it
  - #(p + "btwo") is the next item

  #(p + "after") follows the list
]
#pagebreak()
#callout(label: [Calloutlabel], prose("Callout"))
#pagebreak()
#panel(label: [Panellabel], prose("Panel"))
#pagebreak()
#unit([Unitlabel], "note", caps: false)[Unitleadagain holds.][#prose("Unit")]
#pagebreak()
#item(2, [Itemtitleagain], prose("Item"))
#pagebreak()
#decision(1, [Decisionquestion], prose("Decision"))
#pagebreak()
#addendum([2026-10-21], prose("Addendum"), label: [Addendumlabel], caps: false)
