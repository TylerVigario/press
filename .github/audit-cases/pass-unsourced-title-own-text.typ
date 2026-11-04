// A title still to be named, printed by footer() on each of two pages, under a head of the
// document's own whose title() prints its own words: the audit counts the one item once.
// audit-cases.sh checks the count.
#import "/lib.typ": *

#show: base.with(title: unsourced[Opening hours], author: "press")
#set page(footer: footer())

#align(center, title[Hours])

The office opens at nine on weekdays.
#pagebreak()
It closes at five.
