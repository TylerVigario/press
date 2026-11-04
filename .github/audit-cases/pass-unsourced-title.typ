// A title still to be named, on a document of three pages: brief prints it in its header and in
// every page's footer, and the audit counts the one item once. audit-cases.sh checks the count.
#import "/lib.typ": *

#show: brief.with(title: unsourced[Opening hours], author: "press")

= Hours
Monday to Friday, 9 to 5.
#pagebreak()
= Holidays
Closed on public holidays.
#pagebreak()
= Contact
Ask at the front desk.
