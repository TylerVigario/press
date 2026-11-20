// For continued-gap.sh: a letter whose pages after the first are half a point apart in width,
// from 4pt narrower than its writer's name fills the left of continued()'s header beside the
// date to 24pt wider, so the name's end comes to every distance from the date, on one line and
// wrapped. The name and the date are words pdftotext gives a box each.
#import "/lib.typ": *

#show: letter.with(title: [Letter], author: "Writerone Writertwo Writerthree",
  date: [18 November 2026])

Body.
#context {
  let name = measure(text(size: sz.fine)[Writerone Writertwo Writerthree]).width
  let date = measure(text(size: sz.fine)[18 November 2026]).width
  for i in range(-8, 49) {
    page(width: 2 * name + date + 2in + i * 0.5pt, height: 2in, margin: (x: 1in, y: 0.75in))[Body.]
  }
}
