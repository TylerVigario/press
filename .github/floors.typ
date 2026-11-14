// Every part of press's that draws in its inks, tints or rules, in one of its templates, set for
// a calibration, as .github/floors.sh measures it. --input template= names the template, and
// --input calibration= what it is given: none, press's own calibration given by name (own), or
// floors far above press's own (floors): the lightest ink 9:1, the palest fill 1.3:1 and every
// rule 1.5pt. Compiling it asserts what calibrated() hands back.
#import "/lib.typ": *

#let floors = (ink: 9, fill: 1.3,
  rule: (rule-hair: 1.5pt, rule-mid: 1.5pt, slate: 1.5pt, ink: 1.5pt))

// calibrated() hands back press's own presets for press's own calibration, and for floors above
// them, each ink and tint darkened to its floor, its hue kept, and each rule its floor.
#let own = calibrated(calibration)
#for (name, colour) in _inks + _tints { assert(own.at(name) == colour, message: name) }
#let set-for = calibrated(floors)
#for (name, colour) in _inks {
  let k = _contrast(set-for.at(name))
  assert(k >= floors.ink - 0.01, message: name + " reaches " + str(k) + ", not 9:1")
  if _contrast(colour) < floors.ink {
    let (_, c0, h0, ..) = oklch(colour).components()
    let (_, c1, h1, ..) = oklch(set-for.at(name)).components()
    assert(c0 < 0.02 or calc.abs((h1 - h0) / 1deg) < 3, message: name + " changed its hue")
  }
}
#for (name, colour) in _tints {
  assert(_contrast(set-for.at(name)) >= floors.fill - 0.001, message: name)
}
#assert(set-for.rule == floors.rule)

#let given = (
  "none": (:),
  "own": (calibration: calibration),
  "floors": (calibration: floors),
).at(sys.inputs.at("calibration", default: "none"))
#let name = sys.inputs.at("template", default: "brief")
#let args = (
  base: (title: [Floors], author: "press"),
  brief: (title: [Floors], author: "press", meta: [a check], footer: footer(status: [draft]),
    legend: ([Colour is state.], chip([DONE], "ok"), chip([CHECK], "warn"), chip([NO], "bad"))),
  letter: (title: [Floors], author: "press", contact: ([Town, ST], [555-0100]),
    date: [1 January 2026]),
  recipe: (title: [Floors], author: "press", yield: [serves 4], method: [stovetop],
    time: [about 30 min], intro: [A check of the floors.]),
  resume: (title: [Floors], author: "press", headline: [A check of the floors],
    contact: ([Town, ST], [555-0100])),
).at(name)
#let template = (base: base, brief: brief, letter: letter, recipe: recipe, resume: resume).at(name)
#show: template.with(..args, ..given)

= A section

#eyebrow[An eyebrow] #text(fill: ink-faint)[A document's own text in ink-faint.]
#unsourced[An open item], #unsourced(kind: "missing")[not recorded] and
#unsourced(kind: "estimate")[\$18.00]. A source #src("one"), and a #link("https://example.org")[link].

#for tone in ("note", "ok", "warn", "bad") {
  callout(tone: tone, label: [A #tone callout])[Its body.]
  unit([A #tone unit], tone, [Its lead.], [Its body.])
}
#chip([BOXED], "ok") #chip([UNBOXED], "bad", boxed: false)
#decision(1, [A question?], [Its note.])
#item(1, [An item], [Its body.])
#panel(label: [A panel])[Its body.]
#flow([a], [b], [c])
#addendum([2026-01-01], [A later note.])
#sheet((auto, 1fr), ([Item], [Amount]), [One], [1], [Two], [2], [Three], [3])
#checkbox() A box to tick.
#writein(1, label: [note])

```sh
echo code
```

#section(color: bad)[
  = A section in a state
  == A labelled hairline
  Its text.
]

#sources(("one", [A source], "https://example.org/one"))
#signature(closing: [Sincerely,], dated: false)
#stamp[A stamp's closing line.]
