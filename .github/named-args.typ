// For named-args.sh: one of the parts that take any number of items, chosen by `part` through
// --input, given an argument by name that it does not take, `extra`; `letterhead-two` gives
// letterhead() two, as letter()'s own names, `contact` and `phone`.
#import "/lib.typ": *

#set document(title: [Named], author: "Sam Example")
#set text(font: face-text)
#let part = sys.inputs.at("part")
#if part == "letterhead" { letterhead([Town], extra: 1) }
#if part == "letterhead-two" { letterhead(contact: [Town], phone: [555 0100]) }
#if part == "re" { re([Order 12], extra: 1) }
#if part == "enclosures" { enclosures([Invoice], extra: 1) }
#if part == "units" { units([One], [Two], extra: 1) }
#if part == "sheet" { sheet((1fr, 1fr), ([A], [B]), [C], [D], extra: 1) }
#if part == "steps" { steps(([Mix], [Stir.]), extra: 1) }
#if part == "flow" { flow([Plan], [Build], extra: 1) }
#if part == "src" { [A claim#src("a", extra: 1).] }
#if part == "sources" { sources(("a", [A source.], none), extra: 1) }
#if part == "none" {
  letterhead([Town])
  re([Order 12])
  enclosures([Invoice])
  units([One], [Two])
  sheet((1fr, 1fr), ([A], [B]), [C], [D])
  steps(([Mix], [Stir.]))
  flow([Plan], [Build])
  [A claim#src("a").]
  sources(("a", [A source.], none))
}
