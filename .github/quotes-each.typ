// For quotes.sh: a string under the template `--input template=` names, which must print its
// quote curled under each of the five, as under brief.
#import "/lib.typ": *

#let template = (base: base, brief: brief, letter: letter, recipe: recipe, resume: resume)
#show: template.at(sys.inputs.at("template")).with(title: [Notes], author: "press")

#"The tenant's notes"
