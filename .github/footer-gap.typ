// For footer-gap.sh: footer() on pages half a point apart in width, from 2pt narrower than its
// title and status and its stamp and page set side by side to 14pt wider, so the title's end
// comes to every distance from the stamp. Each page is page 1 of 1, as the width is measured. The
// stamp is passed in as press-updated.
#import "/lib.typ": *

#set document(title: "Quarterly supplier review")
#set text(font: face-text)
#context {
  let left = measure(text(size: sz.micro)[Quarterly supplier review · draft]).width
  let right = measure(text(size: sz.micro)[#updated() · 1 / 1]).width
  for i in range(-4, 29) {
    page(width: left + right + 1in + i * 0.5pt, height: 1in, margin: 0.5in,
      footer: footer(status: [draft]))[#counter(page).update(1)]
  }
}
