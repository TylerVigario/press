// A title still to be named, printed by a head of the document's own through typst's title(),
// and by footer() on each of two pages: the audit counts the one item once. audit-cases.sh
// checks the count.
#import "/lib.typ": *

#show: base.with(title: unsourced[Opening hours], author: "press")
#set page(footer: footer())
#show title: set text(size: sz.title, weight: "bold")

#align(center, title())

The office opens at nine on weekdays.
#pagebreak()
It closes at five.
