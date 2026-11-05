// Sources under brief, for sources.sh: three given in an order the text does not cite them in,
// one of them with no address. `--input case=unknown` cites a key no sources() gives, and
// `case=twice` gives a key twice.
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
