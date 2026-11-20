// printers.typ — press's own calibration and printer(), for .github/printers.sh, which writes the
// printers.csv beside lib.typ that the case reads: its header alone (none), three printers at
// normal quality and two in economy mode, one printed twice in each (recorded), or two at normal
// quality (even). A case named for a call makes it, where printers.sh expects the build to stop.
#import "/lib.typ": *

#let case = sys.inputs.at("case", default: "none")
// Two lengths or numbers the same but for a float's last digits.
#let near(a, b) = calc.abs(if type(a) == length { (a - b).pt() } else { a - b }) < 1e-6
#let same(got, want, what) = {
  for (key, v) in want {
    if type(v) == dictionary { same(got.at(key), v, what + "." + key) } else {
      assert(near(got.at(key), v), message: what + "." + key + " is " + repr(got.at(key))
        + ", where it should be " + repr(v))
    }
  }
}
#let reading(t, b, l, r, ink, fill, hair, mid, slate, ink-rule) = (
  edges: (top: t * 1mm, bottom: b * 1mm, left: l * 1mm, right: r * 1mm), ink: ink, fill: fill,
  rule: (rule-hair: hair * 1pt, rule-mid: mid * 1pt, slate: slate * 1pt, ink: ink-rule * 1pt),
)

#if case == "none" {
  // press's numbers before it had a sheet, printer()'s with them, and no margin widened.
  same(calibration, (edges: (top: 0.48in, bottom: 0.48in, left: 0.48in, right: 0.48in),
    rule: (rule-hair: 0.4pt, rule-mid: 0.5pt, slate: 0.5pt, ink: 0.5pt)), "calibration")
  assert(calc.abs(calibration.ink - 5.05) < 0.005 and calc.abs(calibration.fill - 1.07) < 0.005,
    message: "calibration's ink and fill are " + repr((calibration.ink, calibration.fill))
      + ", where they should be ok's 5.05 and paper-tint's 1.07")
  assert.eq(printer(), calibration)
  assert.eq(calibrated(calibration).dense, dense)
} else if case == "recorded" {
  // Each number the middle of the three printers' latest at normal quality, Alpha A1's of
  // 2026-12-01 and not its row of 2026-11-01 after it, quoted; each in economy mode the mean of the two,
  // Gamma G3's the later of its two rows of one date. A median band wider than 0.48in widens
  // a preset's margin by as much.
  let median = reading(4, 14, 5, 6, 6, 1.2, 0.5, 0.5, 0.5, 0.5)
  same(calibration, median, "calibration")
  assert.eq(printer(), calibration)
  same(printer(mode: "economy"), reading(5, 16.5, 5.5, 7, 9, 1.6, 0.7, 0.65, 0.55, 0.7),
    "printer(mode: \"economy\")")
  same(printer("Alpha A1"), reading(4, 17, 6, 6, 6, 1.2, 0.5, 0.6, 0.5, 0.5), "Alpha A1")
  same(printer("Beta, B2"), reading(3, 12, 5, 5, 7, 1.1, 0.4, 0.5, 0.6, 0.4), "Beta, B2")
  same(printer("Gamma G3", mode: "economy"), reading(6, 16, 5, 8, 10, 1.7, 0.8, 0.6, 0.5, 0.8),
    "Gamma G3 in economy mode")
  assert(near(calibrated(calibration).dense.margin.bottom, dense.margin.bottom + 14mm - 0.48in),
    message: "dense's bottom margin, set for the median, is "
      + repr(calibrated(calibration).dense.margin.bottom))
  assert(near(calibrated(printer("Alpha A1")).dense.margin.bottom,
    dense.margin.bottom + 17mm - 0.48in), message: "dense's bottom margin, set for Alpha A1, is "
      + repr(calibrated(printer("Alpha A1")).dense.margin.bottom))
} else if case == "even" {
  same(calibration, reading(3.5, 14.5, 5.5, 5.5, 6.5, 1.15, 0.45, 0.55, 0.55, 0.45), "calibration")
} else {
  let calls = (
    unknown: () => printer("Delta D4"),
    unrecorded-mode: () => printer("Beta, B2", mode: "economy"),
    no-economy: () => printer(mode: "economy"),
    mode: () => printer(mode: "draft"),
    two: () => printer("Alpha A1", "Beta, B2"),
    named: () => printer(model: "Alpha A1"),
    string: () => printer(1),
  )
  assert(case in calls, message: "printers.typ has no case " + case)
  let _ = (calls.at(case))()
}

#show: brief.with(title: [Printers], author: "press", calibration: printer())
The case passed.
