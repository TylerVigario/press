// The résumé template, and the part only a résumé uses.
// A template is composed from tokens, parts and composition, and never from another template, so
// it can be read, or copied, on its own.

#import "tokens.typ": *
#import "parts.typ": *

// A résumé is read first by an applicant-tracking parser, which takes its text in the order the
// page gives it, and then by a person. So it keeps to one column: a section is a heading, and a
// role is one paragraph, read in the order it is printed.

// One role: the role in bold, the organisation after it and then its dates, in one paragraph and
// in that order on the line, so a parser reads the three in order however it reads a page. A
// parser that groups a page's text by where it stands reads dates set apart at the right of the
// line after every role, and a role read beside another role's dates is a wrong work history.
// The dates are kept whole with the dot before them, so a line that cannot hold them carries
// them onto the next. `stacked` puts the organisation and its dates on a line of their own,
// under the role, for organisations that carry a place. `flush: true` sets the dates at the
// right of the line instead, on a role's last line, where a parser that reads a page's text in
// the order it is written still reads them in order. A page never ends on a role: the entry
// stays with what follows it.
//
//   #entry([Network technician], [Valley Broadband], [2021 – present])
#let entry(role, org, dates, stacked: false, flush: false) = block(width: 100%, above: 1em,
  below: _part-gap, sticky: true, {
  if flush {
    // The dates, pushed right. Joined to an empty box, so dates that do not fit on the line go to
    // the next one whole and still at the right: a line drops space that starts it, not a box.
    let when = [#box(width: 0pt)#sym.wj#h(1fr)#sym.wj#box(text(fill: ink-soft, dates))]
    if stacked { [#strong(role) #when \ #org] } else { [#strong(role) — #org #when] }
  } else {
    let when = box(text(fill: ink-soft)[#sym.dot.c #dates])
    if stacked { [#strong(role) \ #org #when] } else { [#strong(role) — #org #when] }
  }
})


// A résumé: one column on a full sheet, with no footer. The head is the writer's name, from the
// document's author, with the headline and a line of contact details under it; `centred` centres
// it, and a letter that goes with it passes centred: true and the same face. A section is a
// heading, `= Experience`, in the accent and ruled beneath, and a role is an entry(). `size` is
// the body text, and the headline, the contact line and the headings are sized from it; the name
// is sz.title whatever it is. `caps: false` keeps the headings' case, which upper() would change.
// A set rule after the show rule changes a heading's gaps: `#show heading: set block(above: 8pt)`
// for the space above, `below:` for the space under the rule, and `inset: (bottom: 2pt)` for the
// space between the title and its rule. `contact` is a list of items, or one item alone.
// `preset` is the page, and `calibration` is the printer's numbers, which set its margins, inks,
// tints and rules: tokens.typ's `calibration` says how. `lang` is the résumé's language, `"es"`
// for Spanish: left out, it is the document's own, typst's English unless it sets another.
//
//   #show: resume.with(title: [Your Name — Résumé], author: "Your Name",
//     headline: [Network and systems], contact: ([Town, ST], link("mailto:you@example.com")))
#let resume(
  title: none, author: (), headline: none, contact: (), face: face-text, centred: false,
  size: sz.small, accent: slate, caps: true,
  preset: (paper: "us-letter", margin: (x: 0.6in, y: 0.5in)), calibration: calibration,
  lang: auto, body,
) = {
  let writer = _author(author)
  set document(title: title, author: writer.meta)
  set page(.._page(preset, calibration))
  // The calibration, applied to all the template sets: its inks, its strokes and its bands.
  show: _calibrate.with(calibration)
  // The paragraph before a signature, kept on its page.
  show par: _signed
  set text(font: face, size: size, fill: ink, ..if lang != auto { (lang: lang) })
  // Paragraphs further apart than a list's items, and items than lines, so each reads as one:
  // a paragraph ends where its gap shows, and the one after a list is not its last item's.
  set par(leading: 0.52em, spacing: 0.8em)
  // A list's items are further apart than the lines within one, so a wrapped item reads as one.
  set list(indent: 0.65em, body-indent: 0.34em, spacing: 0.65em)
  set enum(spacing: 0.65em)
  // Code is set a step below the text around it, as sz.fine is to sz.small; typst's own rule for
  // raw sets it at 0.8em first, which this is relative to.
  show raw: set text(font: face-mono, size: sz.fine / sz.small / 0.8 * 1em)
  // Equations in the math face that sits with the text, not typst's own serif one.
  show math.equation: set text(font: face-math)
  // typst curls a quote typed in markup and prints one in a string as it is, so a string read
  // from data, or a title given as one, would print straight beside curled prose. This curls a
  // string's quotes by typst's own rules, so a page has one form whichever way its text came.
  // Code and math keep theirs straight, and so does an address link-note prints.
  show text: _curl
  show raw: set smartquote(enabled: false)
  show math.equation: set smartquote(enabled: false)
  show raw.where(block: true): code
  show link: link-note
  let contact = if type(contact) == array { contact } else { (contact,) }
  show heading: set block(above: 1.1em, below: 0.6em, inset: (bottom: 0.3em),
    stroke: (bottom: _stroke-in(calibrated(calibration), 0.5pt, rule-mid)), sticky: true)
  show heading: it => block(width: 100%, text(size: 1.1 * size, weight: 700, fill: accent,
    tracking: 0.5pt, if caps { upper(it.body) } else { it.body }))

  // The name's box ends at its descenders, not its baseline, so the gap under it clears a g or
  // a y at any body size.
  let head = block(width: 100%, above: 0pt, below: 1.2em, context stack(spacing: 0.6em,
    text(size: sz.title, weight: 700, bottom-edge: "descender", _writer(what: "a résumé")),
    ..if headline != none { (text(size: 1.1 * size, fill: accent, headline),) },
    ..if contact.len() > 0 {
      (text(size: 0.95 * size, fill: ink-soft, contact.join(text(fill: ink-faint)[ #sym.dot.c ])),)
    },
  ))
  // The title is counted here when nothing in the document prints it.
  _title-start()
  writer.start
  if centred { align(center, head) } else { head }
  body
}
