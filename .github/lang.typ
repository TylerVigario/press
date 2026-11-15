// A document in Spanish, in one of press's templates, as .github/lang.sh reads it. --input
// template= names the template, and --input where= where the document gives its language: at its
// start (start), as the template's lang (template), under the template's show rule (under), or
// nowhere (none), where it is typst's English.
#let where = sys.inputs.at("where", default: "none")
#set text(lang: "es") if where == "start"
#import "/lib.typ": *

#let name = sys.inputs.at("template", default: "brief")
#let args = (
  base: (title: [Idioma], author: "press"),
  brief: (title: [Idioma], author: "press"),
  letter: (title: [Idioma], author: "press", date: [6 de noviembre de 2026],
    header: continued(words: (page: [Página]))),
  recipe: (title: [Idioma], author: "press"),
  resume: (title: [Idioma], author: "press"),
).at(name)
#let template = (base: base, brief: brief, letter: letter, recipe: recipe, resume: resume).at(name)
#show: template.with(..args, ..if where == "template" { (lang: "es") })
#set text(lang: "es") if where == "under"

Llegó "a tiempo".
