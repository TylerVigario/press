// base has no starter, so this document stands in for one: it applies base, and templates.sh
// compiles it, which fails on an error or a warning.
#import "/lib.typ": *

#show: base.with(title: [Probe], author: "press", preset: dense)

A paragraph with a #link("https://example.com/page")[link] and `inline code`.

- a list
- of two

```sh
echo a block of code
```
