// Two items only the owner can supply, called as markup, and a value no one will and a box to
// tick by hand, which are not among them. The audit counts what remains and does not fail:
// audit-cases.sh also checks the count it prints.
#import "/lib.typ": *

#show: brief.with(title: [Open items], author: "press")

The account number is #open[from the statement], due #open[the date on the notice]; the branch
is #missing[not recorded].

#checkbox() Signed and dated.
