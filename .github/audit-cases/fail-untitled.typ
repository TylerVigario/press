// A document under a template given no title: typst writes none into its PDF, and says nothing.
// expect: has no title
#import "/lib.typ": *
#show: brief.with(author: "press")

The rack draws 2.4 kW.
