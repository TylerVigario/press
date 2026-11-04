// Every part and template heading that uppercases its label, under the template `--input
// template=` names and with `caps:` as `--input caps=` gives it, for caps.sh. Each label is "pH"
// and the part's name, which caps: false must print as written.
#import "/lib.typ": *

#let caps = sys.inputs.at("caps", default: "true") == "true"
#let template = (brief: brief, recipe: recipe, resume: resume).at(
  sys.inputs.at("template", default: "brief"))
#show: template.with(title: [Probe], author: "press", caps: caps)

= pHheading
== pHsubheading
#unit([pHunit], "note", caps: caps)[A lead.][A body.]
#callout(label: [pHcallout], caps: caps)[A body.]
#panel(label: [pHpanel], caps: caps)[A body.]
#addendum([2026-10-21], label: [pHaddendum], caps: caps)[A body.]
#eyebrow([pHeyebrow], caps: caps)
