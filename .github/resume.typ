// The entries a résumé has, for reading-order.sh: one on a line; a role long enough to wrap, its
// dates on its last line; one whose dates do not fit on its last line and take one of their own;
// and a stacked one. reading-order.sh reads its text and fails when any is out of order.
#import "/lib.typ": *

#show: resume.with(title: [Probe], author: "Pat Example", headline: [Network and systems],
  contact: ([Town, ST], link("mailto:pat@example.com")))

= Experience

#entry([Network technician], [Valley Broadband], [2021 – present])
- A result.

#entry([Senior field operations supervisor and technical crew lead for utility inspection programs],
  [Organisation Name Incorporated], [2017 – 2021])
- A result.

#entry([Technician with a role long enough], [Organisation Name That Fills The Line To The Edge Now],
  [Jan 2014 – Dec 2016])
- A result.

#entry([Field technician], [Organisation, Town, ST], [2012 – 2014], stacked: true)
- A result.
