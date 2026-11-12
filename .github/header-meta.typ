// For header-meta.sh: header() with the title and meta it is given through --input, `title`
// and `meta`, words each one, so pdftotext gives each word a box of its own.
#import "/lib.typ": *

#set document(title: sys.inputs.at("title"))
#set page(width: 6in, height: 3in, margin: 0.5in)
#set text(font: face-text)
#header(meta: sys.inputs.at("meta"))
