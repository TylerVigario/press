// A title still to be named, printed by footer() on every page but the first, a cover set
// without one: the audit counts the one item once. audit-cases.sh checks the count.
#import "/lib.typ": *

#show: base.with(title: unsourced[Opening hours], author: "press")
#set page(footer: none)

Opening hours, for the front desk.
#set page(footer: footer())
#pagebreak()
Monday to Friday, 9 to 5.
#pagebreak()
Closed on public holidays.
