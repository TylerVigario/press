// Paragraphs and lists under the template `--input template=` names, for list-spacing.sh: a
// paragraph of two lines and the next, then a bulleted list, a numbered one and a checklist whose
// first item has a second line, and a paragraph after the lists.
#import "/lib.typ": *

#let template = (brief: brief, base: base, recipe: recipe, resume: resume).at(
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
