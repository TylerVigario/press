// furniture-link.typ — a link in a page's header or footer, for .github/furniture-link.sh, which
// gives the case: brief's footer(status:), a header a letter is given, or the footer of a page
// no template sets, its margins typst's own. Each runs onto a second page, a link on each.
#import "/lib.typ": *

#let case = sys.inputs.at("case", default: "brief")
#let pages = [
  The first page cites #link("https://example.org/one")[one].
  #pagebreak()
  The second page cites #link("https://example.org/two")[two].
]

#if case == "brief" {
  show: brief.with(title: [Probe], author: "Sam Example",
    footer: footer(status: link("https://example.org/status")[status page]))
  pages
} else if case == "letter" {
  show: letter.with(title: [Probe], author: "Sam Example", date: [6 November 2026],
    header: [Sam Example · #link("https://example.org/letters")[letters]])
  pages
} else {
  set page(footer: [Probe · #link("https://example.org/home")[home]])
  show link: link-note
  pages
}
