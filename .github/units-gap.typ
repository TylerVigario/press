// Units under each pack, for units-gap.sh, with the paragraph spacing `--input spacing=` sets.
// Each `<mark>` sits at the same place in its unit, so two marks one above the other are a unit's
// height and the gap apart. `<gaps>` holds the gap under each pack, and `<balance>` whether
// "stacks" split four units where its columns come out most level, counting the gaps in their
// heights.
#import "/lib.typ": *

#let spacing = eval(sys.inputs.at("spacing", default: "0.8em"))
#show: brief.with(title: [Probe], author: "press")
#set par(spacing: spacing)

#let u(name, extra: 0pt) = unit([Pump], "ok")[#metadata(name)<mark>Holds 40 psi.][#v(extra)]
// A unit's height, at a width its words fit on one line in under every pack.
#let height() = measure(block(width: 3in, u("probe"))).height

#units(pack: "single", u("single-1"), u("single-2"))
#units(pack: "stacks", u("stacks-1"), u("stacks-2"), u("stacks-3"))
#units(pack: "grid", u("grid-1"), u("grid-2"), u("grid-3"))

// Four units for "stacks": A, taller than B, C and D by a unit's height and 3pt. Counting the
// gaps between units, B, C and D on the right are a unit and 9pt taller than A alone, and A and B
// a unit and 3pt taller than C and D, so B goes left with A; not counting them, B, C and D are a
// unit less 3pt taller than A, and B goes right.
#context units(pack: "stacks", u("A", extra: height() + 3pt), u("B"), u("C"), u("D"))

#context {
  let at(name) = query(<mark>).find(m => m.value == name).location().position()
  let gap(a, b) = at(b).y - at(a).y - height()
  [#metadata((
    single: gap("single-1", "single-2"),
    stacks: gap("stacks-1", "stacks-2"),
    grid: gap("grid-1", "grid-3"),
  ))<gaps>]
  [#metadata(at("B").x == at("A").x)<balance>]
}
