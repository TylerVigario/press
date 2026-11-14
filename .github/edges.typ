// Two pages or more in one of press's templates, set for a calibration, as .github/edges.sh
// measures them. --input template= names the template, and --input calibration= what it is
// given: none, press's own calibration given by name (own), or bands of 1in at every edge
// (wide), where press's own are 0.48in.
#import "/lib.typ": *

#let given = (
  "none": (:),
  "own": (calibration: calibration),
  "wide": (calibration: (edges: (top: 1in, bottom: 1in, left: 1in, right: 1in))),
).at(sys.inputs.at("calibration", default: "none"))
#let name = sys.inputs.at("template", default: "brief")
#let args = (
  base: (title: [Edges], author: "press"),
  brief: (title: [Edges], author: "press", meta: [a check], footer: footer(status: [draft])),
  letter: (title: [Edges], author: "press", contact: ([Town, ST], [555-0100]),
    date: [1 January 2026]),
  recipe: (title: [Edges], author: "press", yield: [serves 4], method: [stovetop],
    time: [about 30 min], intro: [A check of the edges.]),
  resume: (title: [Edges], author: "press", headline: [A check of the edges],
    contact: ([Town, ST],)),
).at(name)
#let template = (base: base, brief: brief, letter: letter, recipe: recipe, resume: resume).at(name)
#show: template.with(..args, ..given)

= A section

#lorem(1100)
