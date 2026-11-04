// A title still to be named, on a résumé, which prints it nowhere: the PDF's title still carries
// it, and the audit counts the one item once. audit-cases.sh checks the count.
#import "/lib.typ": *

#show: resume.with(title: unsourced[Résumé], author: "press")

= Experience
#entry([Role], [Organisation], [2021 – present])
