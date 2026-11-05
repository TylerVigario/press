// Quotes under brief, for quotes.sh, its title given as a string. Each case is three lines that
// must print alike: its quotes typed curled, the same typed straight in markup, and given as a
// string. After them, the places a quote stays straight: code, math, and an address link-note
// prints, bare and in a footnote.
#import "/lib.typ": *

#show: brief.with(title: "The Tenant's Notes", author: "press")

k1 Each follows its upstream’s own tag, “quoted” and ‘single’ ones

k2 Each follows its upstream's own tag, "quoted" and 'single' ones

k3 #"Each follows its upstream's own tag, \"quoted\" and 'single' ones"

t1 #text(tracking: 0.12em, weight: 700)[A RELEASE’S INPUTS, WORD FOR WORD]

t2 #text(tracking: 0.12em, weight: 700)[A RELEASE'S INPUTS, WORD FOR WORD]

t3 #text(tracking: 0.12em, weight: 700, "A RELEASE'S INPUTS, WORD FOR WORD")

m1 Paid Sam’s share (it’s) and “some” today

m2 Paid Sam's share (it's) and "some" today

m3 Paid #"Sam's" share (#"it's") and #"\"some\"" today

n1 A 12″ board, 5′ long

n2 A 12" board, 5' long

n3 #"A 12\" board, 5' long"

g1 #text(lang: "de")[Er sagte „hallo“ und ‚tschüss‘ heute]

g2 #text(lang: "de")[Er sagte "hallo" und 'tschüss' heute]

g3 #text(lang: "de", "Er sagte \"hallo\" und 'tschüss' heute")

z0 Straight: `echo 'it's' "x"` and math $"o'clock"$, a bare #link("https://example.org/bare'path")
and #link("https://example.org/foot'note")[a noted one].

```sh
grep 'it'\''s' "a file"
```
