// A title still to be named, printed by footer() alone, on a document of three pages with no
// header(): the audit still counts the one item, once. audit-cases.sh checks the count.
#import "/lib.typ": *

#show: base.with(title: unsourced[Opening hours], author: "press")
#set page(footer: footer())

Monday to Friday, 9 to 5.
#pagebreak()
Closed on public holidays.
#pagebreak()
Ask at the front desk.
