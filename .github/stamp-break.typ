// A stamp under brief, for stamp-break.sh: it starts below a spacer that leaves room at the
// page's foot for its hairline and not for the first line of its words. With
// `--input break=yes` a page break goes before it, which is where the whole stamp belongs. The
// spacer is drawn, as a document's content is: an empty one lets the heading above it go to the
// next page with the stamp.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

= A section
#block(height: 8.5in, width: 100%, stroke: 0.5pt + ink-faint)
#if sys.inputs.at("break", default: "no") == "yes" { pagebreak() }
#stamp[Stamp words begin. #lorem(25)]
