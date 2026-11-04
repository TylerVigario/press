// Inline code and a code block under the template `--input template=` names, for code-size.sh:
// each template sets code in press's mono face, a step below its body text.
#import "/lib.typ": *

#let template = (brief: brief, base: base, recipe: recipe, letter: letter, resume: resume).at(
  sys.inputs.at("template", default: "brief"))
#show: template.with(title: [Probe], author: "press")

In the body, `codeface`.

```
codeblock
```
