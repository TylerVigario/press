// signature-page.typ — for .github/signature-page.sh, under the template it gives: 36 letters,
// each on pages of its own and each a paragraph longer than the one before, so that in some the
// last paragraph ends too near a page's foot for the signature after it. Letter K's paragraphs
// lead with "Case K, paragraph I" and its last with "Case K ends", and it is signed by Signer K.
#import "/lib.typ": *
#let template = sys.inputs.at("template", default: "letter")
#let templates = (base: base, brief: brief, letter: letter, recipe: recipe, resume: resume)
#show: templates.at(template).with(title: [Signed], author: "press")

#for k in range(1, 37) {
  for i in range(1, k) [
    Case #k, paragraph #i. The meter was read on the first of the month, and the reading on the
    bill is not the one on the meter.

  ]
  [
    Case #k ends. The meter was read on the first of the month, and the reading on the bill is
    not the one on the meter.

  ]
  signature(name: [Signer #k], closing: [Sincerely,])
  pagebreak(weak: true)
}
