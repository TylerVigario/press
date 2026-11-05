// Sheets under brief, for sheet-row.sh. The first two start below a spacer that leaves room at
// the page's foot for its first row and the first lines of its second, not for all of the second.
// The third's second row is taller than a page.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

#pagebreak()
#block(height: 7.5in, width: 100%)
#sheet((1fr, 2fr), ([Claim], [Evidence]),
  [A short claim], [#lorem(30)],
  [Whole claim], [Whole evidence begins. #lorem(120) Whole evidence ends.],
)

#pagebreak()
#block(height: 7.5in, width: 100%)
#sheet((1fr, 2fr), ([Claim], [Evidence]), breakable: true,
  [A short claim], [#lorem(30)],
  [Split claim], [Split evidence begins. #lorem(120) Split evidence ends.],
)

#pagebreak()
#sheet((1fr, 2fr), ([Claim], [Evidence]),
  [A short claim], [#lorem(30)],
  [Tall claim], [Tall evidence begins. #lorem(3000) Tall evidence ends.],
)
