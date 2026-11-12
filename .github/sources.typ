// Sources under brief, for sources.sh: three given in an order the text does not cite them in,
// one of them with no address. `--input case=unknown` cites a key no sources() gives, and
// `case=twice` gives a key twice. `case=second` gives a second list after the first, and
// `case=across` gives in it a key the first list gives.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

#let case = sys.inputs.at("case", default: "")

Bodyword cites the third first #src("gamma") alone. Two at once, named out of order
#src("gamma", "alpha").
The one with no address #src("beta").
#if case == "unknown" [A key nothing gives #src("nosuch").]

#sources(
  ("alpha", [Alphasource title], "https://example.org/alpha"),
  ("beta", [Betasource title], none),
  ("gamma", [Gammasource title], "https://www.example.org/gamma/a/long/path"),
  ..if case == "twice" { (("alpha", [Again], "https://example.org/again"),) },
)

#if case in ("second", "across") [
  A second part cites #src(if case == "second" { "delta" } else { "alpha" }).

  #sources(if case == "second" { ("delta", [Deltasource title], none) }
    else { ("alpha", [Again], none) })
]
