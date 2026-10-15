// Starter skeleton for a letter. COPY this — do not import it.
//
//   sh third_party/press/tools/new.sh docs/<name> letter    (or `just new docs/<name> letter`)
//
// copies it to docs/<name>/main.typ, with the import below rewritten to where press sits.
// In press's own tree the import is relative, ../lib.typ, so the skeleton compiles there.
//
// ---------------------------------------------------------------------------
// What a letter here does:
//
//   1. IT NAMES ITS WRITER AND ITS DATE ONCE. The writer is the document's author, and the
//      date is dateline()'s, the day the letter goes out; letterhead(), signature() and
//      continued() read them from there. It never prints the build stamp: its reader is
//      outside, with no shelf copy to compare.
//   2. MEAT FIRST. The first paragraph says why you are writing and what you ask for.
//   3. IT PRINTS AND IT UPLOADS. One column of real text, which a reader can copy and
//      software reading a cover letter can parse.
//   4. SIGNED IN INK, OR NOT. Keep signature()'s lines for a letter you print and sign;
//      pass `signed: false` for a typed sign-off on a letter sent as a file.
//
// Delete the parts a letter does not use: re(), enclosures(), the continuation header. To
// match a résumé, pass its face to letterhead (face: face-sans), and centre it to match a
// centred header: #align(center, letterhead(…)).
// ---------------------------------------------------------------------------

#import "../lib.typ": *

// The letter's name and its writer, set once: a PDF viewer shows them, and the letter's parts
// print the writer from here.
#set document(title: [Letter to Recipient Name], author: "Your Name")
// Page two onward names the writer, the date and the page; page one has the letterhead.
#set page(..reading, header: continued())
#set text(font: face-text, size: sz.body, fill: ink, lang: "en")
#set par(leading: 0.6em, spacing: 1.05em)
// Links click on screen; one whose text is not its address footnotes the address for paper.
#show link: link-note

#letterhead(
  [123 Street Name, Town, ST 00000],
  [(555) 555-0100],
  link("mailto:you@example.com"),
)

#dateline([15 October 2026])

Recipient Name \
Title \
Organisation \
Street Address \
Town, ST 00000

#re([Account 0000-0000], [date of service 1 January 2026])

Dear Recipient Name,

The first paragraph says why you are writing and what you are asking for, so a reader who
stops here still knows.

The paragraphs after it give what the request rests on: the facts, in the order the reader
needs them, each with the reference that lets them check it.

The last paragraph says what happens next, and how to reach you.

#signature(closing: [Sincerely,])

#enclosures([First enclosure], [Second enclosure])
