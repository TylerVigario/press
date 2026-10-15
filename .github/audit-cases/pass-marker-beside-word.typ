// A link-note footnote marker right after its word, alone in a sheet cell. poppler gives the
// raised marker a line of its own whose box meets the word's, and nothing is drawn on anything.
#import "/lib.typ": *
#set document(title: [Marker beside its word], author: "press")
#set page(..dense)
#set text(font: face-text, size: sz.small)
#show link: link-note
#sheet((1fr, auto, auto), ([Item], [Where], [Price]), size: sz.fine,
  [x], link("https://www.samsung.com/us/")[Samsung], [\$1])
