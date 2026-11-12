// The same warning at two places, which typst prints and exits 0 on: the audit fails it, and
// prints each as typst does, with where it is, so a CI log says which line to fix.
// expect: fail-warning.typ:8:4
#import "/lib.typ": *
#show: base.with(title: [Warnings], author: "press")

One **
Two **
