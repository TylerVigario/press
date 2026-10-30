// Two items only the owner can supply, one called as markup and one as a function, and an
// estimate, through a shorthand the document names; then a value no one will supply and a box to
// tick by hand, which are not counted. The audit counts the open items and the estimates and does
// not fail: audit-cases.sh also checks the counts it prints.
#import "/lib.typ": *

#show: brief.with(title: [Unsourced values], author: "press")

#let est = unsourced.with(kind: "estimate")

The account number is #unsourced[from the statement], due #unsourced([the date on the notice]);
the branch is #unsourced(kind: "missing")[not recorded], and the fee about #est[\$40.00].

#checkbox() Signed and dated.
