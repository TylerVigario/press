// The entries a résumé has, for reading-order.sh: one on a line; a role long enough to wrap; one
// whose organisation fills its line, so its dates cannot stay on it; and a stacked one. Set with
// the dates in the line's flow, entry()'s own, or with --input flush=true at the right of the
// line. reading-order.sh reads its text and fails when any is out of order.
#import "/lib.typ": *

#let flush = sys.inputs.at("flush", default: "false") == "true"

#show: resume.with(title: [Probe], author: "Pat Example", headline: [Network and systems],
  contact: ([Town, ST], link("mailto:pat@example.com")))

= Experience

#entry([Network technician], [Valley Broadband], [2021 – present], flush: flush)
- A result.

#entry([Senior field operations supervisor and technical crew lead for utility inspection programs],
  [Organisation Name Incorporated], [2017 – 2021], flush: flush)
- A result.

#entry([Technician with a role long enough], [Organisation Name That Fills The Line To The Edge Now],
  [Jan 2014 – Dec 2016], flush: flush)
- A result.

#entry([Field technician], [Organisation, Town, ST], [2012 – 2014], stacked: true, flush: flush)
- A result.
