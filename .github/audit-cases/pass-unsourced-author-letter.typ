// A writer still to be named, on a letter of two pages: the letterhead, the page-two header and
// the signature print the name, the PDF's author is its words, and the audit counts the one item
// once. audit-cases.sh checks the count and the author.
#import "/lib.typ": *

#show: letter.with(title: [Letter to the county], author: unsourced[Sam Example],
  date: [6 November 2026])

Dear Ms Example, #lorem(700)

#signature(closing: [Sincerely,], dated: false)
