// A date still to be settled, on a letter of two pages: the date line and the page-two header
// print it, and the audit counts the one item once. audit-cases.sh checks the count.
#import "/lib.typ": *

#show: letter.with(title: [Letter to the county], author: "Sam Example",
  date: unsourced[6 November 2026])

Dear Ms Example, #lorem(700)
