// Three steps, one in a colour of its own, and a list of typst's own after them, for steps.sh: the
// steps must be one list in the PDF's tags, apart from the list after them.
#import "/lib.typ": *
#show: brief.with(title: [Steps], author: "press")

#steps(
  ([Shut the water off], [Turn the valve at the street a quarter turn clockwise.]),
  ([Open the box], [Lift the lid with the hook end of the key.], warn),
  ([Read the meter], [Write down the number on the dial.]),
)

+ A list of typst's own.
+ Its second item.
