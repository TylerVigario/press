// A document importing a file that accepts a finding: only the document's own file may.
// expect: only the document's own file may
#import "/lib.typ": *
#import "shared/accepting.typ": head
#set document(title: [Acceptance in a shared file], author: "press")
#set page(..card)
#set text(font: face-text, size: sz.body)
#head
