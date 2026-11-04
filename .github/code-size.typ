// Inline code under brief, for code-size.sh: in body text, in a sheet at its default size and at
// sz.small, in a lead set larger, and under a document's own rule for raw. Each word is code, and
// its own, so code-size.sh can find it.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

In the body, `codebody`.

#sheet((auto, 1fr), ([Share], [Path]), [Scans], [`codesheet`])

#sheet((auto, 1fr), ([Share], [Path]), size: sz.small, [Scans], [`codesheetsmall`])

#text(size: sz.lead)[In a lead, `codelead`.]

#[#show raw: set text(size: 12pt); Under the document's own rule, `codeown`.]
