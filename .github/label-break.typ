// A labelled callout, panel and unit under brief, for label-break.sh: each starts below a spacer
// that leaves room at the page's foot for its label and not for the line under it.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

#pagebreak()
#block(height: 9in, width: 100%)
#callout(label: [Callout label])[Callout body begins. #lorem(40)]

#pagebreak()
#block(height: 9in, width: 100%)
#panel(label: [Panel label])[Panel body begins. #lorem(40)]

#pagebreak()
#block(height: 9.22in, width: 100%)
#unit([Unit label], "note", [Unit lead begins.], [#lorem(40)], breakable: true)
