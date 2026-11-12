// For recipe-ref.sh: a recipe card whose method points into its reference with typst's own page
// reference, as a brief's act layer points into its depth.
#import "/lib.typ": *

#show: recipe.with(title: [Black beans], author: "press")

= Method
Soak the beans overnight. If they stay hard, see #ref(<trouble>, form: "page").

= Reference <depth>
== Troubleshooting <trouble>
Old beans never soften.
