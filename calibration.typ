// press: accept ink-margin — the edge gauges print into each edge's band on purpose, to measure it
//
// Print calibration sheet for the press token set.
//
// Every scale on it is numbered by its value, so printing it gives numbers rather than a
// verdict: how far from each edge the printer starts to print, whether it prints at actual
// size, and the lightest ink, the palest fill and the thinnest rule it holds, at normal quality
// and in economy mode. Page 1 is where they are written down, and says what each one sets: the
// edge bands are what the page presets must clear. Every value printed is computed from the
// colour or length it labels, so a label never disagrees with what it samples.
//
// Print it on the paper you actually use, at Actual size, duplex, flipping on the long edge
// (the usual setting): once at normal quality, once in economy mode. The edge gauges sit on
// the back of the first sheet and the front of the second, so both sides are measured, and the
// show-through windows on the front of the last sheet, with their fields behind them.
//
// Build it like any document. From a repo that holds press at third_party/press:
//
//   sh third_party/press/tools/build.sh third_party/press/calibration.typ
//
// which writes print/third_party/press/calibration.pdf, and in press itself, `just build
// calibration.typ`. Its gauges print into the edges on purpose, so the line above accepts the
// audit's ink-margin finding.

#import "lib.typ": *

#show: brief.with(title: [Print calibration], author: "press",
  meta: [press #press-version · US Letter · actual size],
  footer: footer(status: [print at Actual size, duplex, normal and economy]))

// The numbers. A colour's contrast on white is WCAG's, from its sRGB components; a grey of a
// given contrast is the lightest 8-bit grey that reaches it, so its label is never above it.
#let _linear(c) = if c <= 0.04045 { c / 12.92 } else { calc.pow((c + 0.055) / 1.055, 2.4) }
#let contrast(colour) = {
  let (r, g, b) = rgb(colour).components(alpha: false).map(c => _linear(c / 100%))
  1.05 / (0.2126 * r + 0.7152 * g + 0.0722 * b + 0.05)
}
#let grey(ratio) = {
  let l = 1.05 / ratio - 0.05
  let c = if l <= 0.0031308 { 12.92 * l } else { 1.055 * calc.pow(l, 1 / 2.4) - 0.055 }
  let v = calc.floor(c * 255)
  rgb(v, v, v)
}
// A number to `d` places, its trailing places kept, so a column of them lines up.
#let fixed(x, d) = {
  let s = str(calc.round(x, digits: d))
  let (whole, ..rest) = s.split(".")
  let frac = rest.at(0, default: "")
  if d == 0 { whole } else { whole + "." + frac + "0" * (d - frac.len()) }
}
#let ratio(colour) = fixed(contrast(colour), 2) + ":1"
#let mm(l) = fixed(l / 1mm, 1) + " mm"

#let note(body) = text(size: sz.micro, fill: ink-soft, body)

// The readings, each with the page that takes it, found where it is.
#let on(target) = context str(locate(target).page())
#let readings = (
  ([1], [Actual size: the 15 cm ruler measures], on(<gauges-front>), [mm]),
  ([2], [Front of a sheet: the band at the top], on(<gauges-front>), [mm]),
  ([], [at the bottom], on(<gauges-front>), [mm]),
  ([], [at the left], on(<gauges-front>), [mm]),
  ([], [at the right], on(<gauges-front>), [mm]),
  ([3], [Back of a sheet: the band at the top], on(<gauges-back>), [mm]),
  ([], [at the bottom], on(<gauges-back>), [mm]),
  ([], [at the left], on(<gauges-back>), [mm]),
  ([], [at the right], on(<gauges-back>), [mm]),
  ([4], [The lightest grey that reads at 8.6 pt], on(<reading-ink>), [:1]),
  ([5], [The palest grey that prints an even fill], on(<reading-fill>), [:1]),
  ([6], [The thinnest rule that prints unbroken: `rule-hair`], on(<reading-rule>), [pt]),
  ([], [`rule-mid`], on(<reading-rule>), [pt]),
  ([], [`slate`], on(<reading-rule>), [pt]),
  ([], [`ink`], on(<reading-rule>), [pt]),
  ([7], [The darkest field that does not show through], on(<reading-solid>), [:1]),
)

#note[
  Each scale on this sheet is numbered by its value. Print it once at normal quality and once in
  economy mode, read off the numbers where your printer gives out, and write them here.
]
#v(4pt)
#sheet((auto, 1fr, auto, 1.1in, 1.1in), ([], [Reading], [Page], [Normal], [Economy]),
  size: sz.small,
  ..readings.map(((n, what, page, unit)) => (
    text(weight: 700, n), block(height: 0.2in, align(horizon, what)), align(horizon, page),
    align(right + bottom, note(unit)), align(right + bottom, note(unit)),
  )).flatten(),
)

== What each number sets

#note[
  *1, actual size.* Every other number assumes it. A page printed scaled moves each bar and
  each scale with it, so a ruler that does not measure what it says means printing the sheet
  again at Actual size.

  *2 and 3, the bands.* No ink prints nearer an edge than its band. press's page presets are
  built to keep ink 0.5 in, #mm(0.5in), from every edge, and the audit fails ink nearer than
  0.48 in, #mm(0.48in): a band wider than either, at any edge or on either side, is the number
  to recalibrate them by.

  *4, ink.* Text in an ink lighter than this fades on this printer, at the smallest size press
  sets. Page #on(<reading-ink>) places press's own text inks on the same scale.

  *5 to 7, fills, rules and solids.* A tint paler than 5 vanishes into the paper, a rule thinner
  than 6 breaks up, and a solid darker than 7 shows through the sheet: a heavier paper is the
  fix for that, not a lighter design, because a heading's band is what makes a section
  skippable at a glance.
]

#stamp[Print it again whenever the paper, the printer or the token set changes.]

// The edge gauges. A page with no margin, so the gauges reach the paper's edges: at the middle
// of each edge, a bar of ink runs from the edge inward beside a ruler in millimetres. A printer
// prints the bar only past its band, so the ruler, read where the bar begins, gives the band.
#let gauge-length = 30mm
#let at(x, y, body) = place(top + left, dx: x, dy: y, body)
// Content centred on a point.
#let centred(x, y, body, w: 30mm, h: 6mm) = at(x - w / 2, y - h / 2,
  box(width: w, height: h, align(center + horizon, body)))
#let tick-length(i) = {
  if calc.rem(i, 10) == 0 { 4mm } else if calc.rem(i, 5) == 0 { 3mm } else { 1.5mm }
}
#let thin = 0.3pt + ink

// One edge's gauge. `edge` is the side it measures; the ruler's 0 is the paper's edge.
#let edge-gauge(edge, w, h) = {
  let n = int(gauge-length / 1mm)
  let label(i) = text(size: sz.micro, fill: ink, str(i))
  if edge == "top" or edge == "bottom" {
    let cx = w / 2
    let y(i) = if edge == "top" { i * 1mm } else { h - i * 1mm }
    at(cx - 4mm, if edge == "top" { 0mm } else { h - gauge-length },
      rect(width: 3mm, height: gauge-length, fill: ink, stroke: none))
    for i in range(0, n + 1) {
      at(cx, y(i), line(length: tick-length(i), stroke: thin))
      if i > 0 and calc.rem(i, 5) == 0 { centred(cx + 7.5mm, y(i), label(i), w: 6mm) }
    }
    let title = text(size: sz.fine, weight: 700)[#upper(edge) · mm from the edge]
    centred(cx, if edge == "top" { gauge-length + 6mm } else { h - gauge-length - 6mm },
      title, w: 60mm)
  } else {
    let cy = h / 2
    let x(i) = if edge == "left" { i * 1mm } else { w - i * 1mm }
    at(if edge == "left" { 0mm } else { w - gauge-length }, cy - 4mm,
      rect(width: gauge-length, height: 3mm, fill: ink, stroke: none))
    for i in range(0, n + 1) {
      at(x(i), cy, line(angle: 90deg, length: tick-length(i), stroke: thin))
      if i > 0 and calc.rem(i, 5) == 0 { centred(x(i), cy + 7mm, label(i), w: 6mm) }
    }
    let title = text(size: sz.fine, weight: 700)[#upper(edge)]
    centred(if edge == "left" { gauge-length / 2 } else { w - gauge-length / 2 }, cy + 13mm,
      title, w: 30mm)
    centred(if edge == "left" { gauge-length / 2 } else { w - gauge-length / 2 }, cy + 17.5mm,
      note[mm from the edge], w: 30mm)
  }
}

// A ruler of `n` steps of `step`, labelled every `every` steps, from (x, y): across, or down.
#let ruler(x, y, n, step, every, unit, down: false) = {
  for i in range(0, n + 1) {
    let half = int(every / 2)
    let l = if calc.rem(i, every) == 0 { 4mm } else if calc.rem(i, half) == 0 { 3mm } else { 1.5mm }
    if down { at(x, y + i * step, line(length: l, stroke: thin)) }
    else { at(x + i * step, y, line(angle: 90deg, length: l, stroke: thin)) }
    if calc.rem(i, every) == 0 {
      let v = text(size: sz.micro, str(int(i / every)) + if i == n { " " + unit } else { "" })
      if down { at(x + 5mm, y + i * step - 1.6mm, v) }
      else { centred(x + i * step, y + 7mm, v, w: 14mm) }
    }
  }
}

#let gauges(side, reading, mark) = page(margin: 0pt, header: none, footer: none, context {
  [#metadata(none)#mark]
  let (w, h) = (page.width, page.height)
  for edge in ("top", "bottom", "left", "right") { edge-gauge(edge, w, h) }
  // Actual size: a ruler of 15 cm and one of 6 in across, and one of 15 cm down.
  let x0 = (w - 150mm) / 2
  at(x0, 52mm, text(size: sz.fine, weight: 700)[Actual size])
  ruler(x0, 60mm, 150, 1mm, 10, "cm")
  ruler(x0, 78mm, 60, 0.1in, 10, "in")
  ruler(52mm, 100mm, 150, 1mm, 10, "cm", down: true)
  at(80mm, 100mm, block(width: 100mm, {
    set text(size: sz.small)
    set par(spacing: 0.9em)
    text(size: sz.head, weight: 700)[#side of the sheet]
    parbreak()
    [*Reading #reading, the bands.* At each edge a bar runs from the paper's edge inward, and the
      printer prints it only past the band it cannot print. Read the ruler where the bar begins:
      that is the band at that edge, in millimetres. Write the four on page 1.]
    parbreak()
    [*Reading 1, actual size.* Lay your own ruler along the rulers here: 15 cm must measure
      15 cm, across and down, and 6 in 6 in. If one does not, the page was scaled, and every
      number on this sheet with it: print it again at Actual size.]
  }))
})

#gauges([Back], [3], <gauges-back>)
#gauges([Front], [2], <gauges-front>)

= 4 · Ink — the lightest grey that reads <reading-ink>

#note[
  The greys step by their contrast on white. Find the first row you would not want to read at
  arm's length, at each size: the row above it is reading 4. Body text is 11 pt; the footer
  and a stamp's closing line are 8.6 pt in italic.
]
#v(5pt)

#let sample = [rnm Il1 0O 3865]
#let sizes = ((sz.micro, "normal"), (sz.micro, "italic"), (sz.fine, "normal"),
  (sz.small, "normal"), (sz.body, "normal"))
#table(
  columns: (auto,) + (1fr,) * sizes.len(),
  stroke: 0.4pt + rule-hair,
  inset: (x: 5pt, y: 4pt),
  align: (right + horizon,) + (left + horizon,) * sizes.len(),
  table.header(note[contrast],
    ..sizes.map(((s, style)) => note[#fixed(s / 1pt, 1) pt#if style == "italic" [ italic]])),
  ..(21, 15, 12, 10, 8, 7, 6, 5.5, 5, 4.5, 4, 3.5, 3).map(r => {
    let g = grey(r)
    (note(ratio(g)), ..sizes.map(((s, style)) => text(size: s, style: style, fill: g, sample)))
  }).flatten(),
)
#v(8pt)

#note[
  press's text inks on the same scale, lightest last. An ink below your reading 4 fades where
  it prints.
]
#v(4pt)
#let inks = (
  ("ink", ink, [body text]),
  ("ink-soft", ink-soft, [secondary text]),
  ("ink-faint", ink-faint, [the footer, a stamp's closing line]),
  ("slate", slate, [links, a section's label]),
  ("bad", bad, [a unit's label, an unboxed chip's]),
  ("warn", warn, [a unit's label, an unboxed chip's]),
  ("ok", ok, [a unit's label, an unboxed chip's]),
).sorted(key: ((_, c, _)) => -contrast(c))
#table(
  columns: (auto, auto, 1fr, 1fr, auto),
  stroke: 0.4pt + rule-hair,
  inset: (x: 5pt, y: 4pt),
  align: (left + horizon, right + horizon, left + horizon, left + horizon, left + horizon),
  table.header(note[ink], note[contrast], note[8.6 pt], note[8.6 pt italic], note[where]),
  ..inks.map(((name, c, where)) => (
    raw(name), note(ratio(c)),
    text(size: sz.micro, fill: c, sample), text(size: sz.micro, style: "italic", fill: c, sample),
    note(where),
  )).flatten(),
)

= 5 · Fills and rules — the palest fill, the thinnest rule <reading-fill>

#note[
  Reading 5: the palest grey that still prints as an even fill, not a scatter of dots or
  nothing at all. press's tints follow, on the same scale.
]
#v(5pt)
#let patch(fill, label) = stack(spacing: 3pt,
  block(width: 100%, height: 0.42in, fill: fill, stroke: none), note(label))
#grid(columns: (1fr,) * 9, gutter: 5pt,
  ..(1.02, 1.04, 1.06, 1.08, 1.10, 1.15, 1.20, 1.30, 1.50).map(r => patch(grey(r), ratio(grey(r)))))
#v(6pt)
#grid(columns: (1fr,) * 9, gutter: 5pt,
  ..(("paper-tint", paper-tint), ("slate-tint", slate-tint), ("ok-tint", ok-tint),
    ("warn-tint", warn-tint), ("bad-tint", bad-tint)).sorted(key: ((_, c)) => contrast(c))
    .map(((name, c)) => patch(c, [#raw(name) #linebreak() #ratio(c)])))
#v(10pt)

#let rules = (("rule-hair", rule-hair), ("rule-mid", rule-mid), ("slate", slate), ("ink", ink))
#block(breakable: false)[
  #note[
    #metadata(none)<reading-rule>Reading 6: in each of press's rule colours, the thinnest rule
    that prints as one unbroken line. press draws its hairlines at 0.4 to 0.75 pt.
  ]
  #v(4pt)
  #table(
    columns: (auto,) + (1fr,) * rules.len(),
    stroke: none,
    inset: (x: 5pt, y: 5pt),
    align: (right + horizon,) + (left + horizon,) * rules.len(),
    table.header(note[width], ..rules.map(((name, c)) => note[#raw(name) #ratio(c)])),
    ..(0.2, 0.3, 0.4, 0.5, 0.6, 0.75, 1, 1.5, 2).map(wd => (
      note[#fixed(wd, 2) pt],
      ..rules.map(((_, c)) => line(length: 100%, stroke: wd * 1pt + c)),
    )).flatten(),
  )
]
#v(6pt)
#text(size: sz.small)[
  A link, as `link-note` prints it: #link("https://github.com/TylerVigario/press")[the press
  source]. On a screen it clicks; on paper its address is in the footnote. Check that the
  underline survives economy mode, since it, not the colour, is what marks a link in greyscale.
]

// The show-through windows, on the front of a sheet, and behind each, on the back, a solid
// field. Each window and its field span the page's width, so flipped on the long edge the back
// lies square behind the front, and each is placed at the same height on both pages.
#let fields = ((1.5, 2, 3, 5, 8, 12, 21).map(r => (grey(r), none))
  + ((slate, [`slate`, a heading's band]), (ink, [`ink`]))).sorted(key: ((c, _)) => contrast(c))
#let field-height = 0.62in
#let field-gap = 0.12in
#let field-top = 0.55in

#pagebreak(to: "odd", weak: true)
#page(header: none, footer: none, {
  [#heading(level: 1, outlined: false, bookmarked: false)[7 · Show-through — the darkest
    field unseen]<reading-solid>]
  for (i, (c, name)) in fields.enumerate() {
    at(0pt, field-top + i * (field-height + field-gap), block(width: 100%, height: field-height,
      stroke: (paint: rule-mid, dash: "dashed", thickness: 0.7pt), radius: 2pt, inset: 6pt,
      note[*#(i + 1)* · #ratio(c)#if name != none [ · #name]]))
  }
  at(0pt, field-top + fields.len() * (field-height + field-gap), note[
    Behind each window, on the back of this sheet, is a solid field of the grey it names. Hold the
    sheet to the light: reading 7 is the darkest field you cannot see through the window.
  ])
})
#page(header: none, footer: none, {
  for (i, (c, _)) in fields.enumerate() {
    at(0pt, field-top + i * (field-height + field-gap), block(width: 100%, height: field-height,
      fill: c, radius: 2pt))
  }
})
