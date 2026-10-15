// A link-note footnote marker between two words of one line, in a sheet cell. poppler joins the
// words around it into one line and gives the raised marker its own, inside that line's box, with
// no glyph touching it.
#import "/lib.typ": *
#set document(title: [Marker mid-line], author: "press")
#set page(..dense)
#set text(font: face-text, size: sz.small)
#set par(leading: 0.52em, spacing: 0.55em)
#show raw: set text(font: face-mono, size: sz.micro)
#show link: link-note
#sheet((1fr, auto, auto), ("Product and licence", "Part", "Price"), size: sz.fine,
  [*Product A*, perpetual — #link("https://www.example.com/a")[a reseller]], `PART-A1`, [\$443.15],
  [#h(8pt) first-year maintenance, compulsory — #link("https://www.example.com/b")[a reseller]], `PART-A2`, [\$212.50],
  [#h(8pt) the same from #link("https://shop.example.com/a")[the vendor's store], version 2025], "", [\$714 + \$324 = \$1,038],
)
