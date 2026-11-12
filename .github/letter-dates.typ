// For letter-dates.sh: two letters in one document, each running onto a second page under
// continued(), for a page that composes its own letter from press's parts.
#import "/lib.typ": *
#set document(title: [Two letters], author: "press")
#set page(..reading, header: continued())
#set text(font: face-text, size: sz.body, fill: ink, lang: "en")

#letterhead("press@example.org")
#dateline[1 January 2026]

Dear Ann, #lorem(900)

#pagebreak()
#letterhead("press@example.org")
#dateline[9 September 2026]

Dear Ben, #lorem(900)
