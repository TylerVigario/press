// highlight.typ — code typst highlights, lines of Typst and of Rust that between them draw every
// colour of typst's theme, for .github/highlight.sh: each line inline on white (white), the lines
// of each language as a code block (code), or each line inline in a chip (chip), a callout
// (callout), a unit (unit), a sheet's head (head) or its stripe (stripe), as --input where= names
// it, alone on a page under base, given the calibration --input calibration= names: press's own
// (own), an ink of 6 (ink-6), or a fill of 1.5 (fill-1.5). --input theme= sets raw's theme: typst's
// own (typst, the default); none, so the page draws only what is not highlighted; or grey, a theme
// of the document's own that sets every comment in #74747c, typst's own comments' colour, 4.63:1 on
// white, and the rest in black. theme=plain sets the lines inline with no press at all, in typst's
// colours as typst gives them, and with where=every, code in each of 20 languages as a block, for
// every colour of typst's theme. The calibration's ink is recorded as <highlight-ink>, its contrast
// on white, as the template takes it.
#import "/lib.typ": *

#let where = sys.inputs.at("where", default: "white")
#let theme = sys.inputs.at("theme", default: "typst")
#let given = ((own: calibration, "ink-6": (ink: 6), "fill-1.5": (fill: 1.5))
  .at(sys.inputs.at("calibration", default: "own")))
#let samples = (
  typ: (
    "= Heading", "*strong* _emph_ `raw` $x^2$ @label <label>", "- item", "+ enum",
    "/ Term: desc", "#let f(x, y: 1) = x + y // a comment", "#set text(size: 10pt, fill: red)",
    "#show heading: it => [#it]", "#if true { \"string\\n\" } else { none }",
    "#import \"/lib.typ\": *", "https://example.com \\ ~ --- 'quote'",
  ),
  rust: (
    "// a comment", "/// doc", "use std::fmt;", "#[derive(Debug)]",
    "pub struct P<'a> { x: &'a str, n: u32 }", "fn main() -> Result<(), Box<dyn Error>> {",
    "let mut v = vec![1, 2.5, 0x1f];", "println!(\"{} {}\\n\", v, 'c');",
    "if let Some(x) = v.get(0) { return Ok(()); }", "match n { 0 => true, _ => false }",
  ),
)
// Every language typst highlights that press samples, for the theme's colours alone.
#let others = (
  python: ("# a comment", "import os", "from x import y as z", "@decorator", "class A(Base):",
    "    \"\"\"doc\"\"\"", "    def f(self, n: int = 3) -> str:",
    "        return f\"{n} \\n\" + 'x' if True else None", "print(len([1, 2.0, 0xff]), r'raw')"),
  js: ("// a comment", "import { a } from 'b';", "const f = async (x = 1) => { return `t ${x}`; };",
    "class C extends D { constructor() { super(); this.n = null; } }",
    "let re = /ab+c/g; if (x === undefined) throw new Error(\"e\");"),
  sh: ("#!/bin/sh", "# a comment", "set -eu", "for f in *.typ; do",
    "  typst compile \"$f\" \"${f%.typ}.pdf\" || exit 1", "done", "echo 'done' > /dev/null 2>&1",
    "case $1 in a) x=$((1 + 2)) ;; esac"),
  json: ("{", "  \"name\": \"press\",", "  \"n\": 1.5,", "  \"ok\": true,", "  \"none\": null,",
    "  \"list\": [1, \"two\"]", "}"),
  toml: ("# a comment", "[package]", "name = \"press\"", "version = \"0.10.0\"", "n = 3",
    "ok = true", "date = 2026-11-27", "[[bin]]", "x = { a = 1 }"),
  yaml: ("# a comment", "name: press", "on:", "  push:", "    branches: [main]", "jobs:", "  a:",
    "    runs-on: ubuntu-latest", "    steps:", "      - run: echo \"x\" # c", "        n: 3",
    "        ok: true", "        anchor: &a ~"),
  html: ("<!doctype html>", "<!-- a comment -->", "<html lang=\"en\">",
    "<a href='x' class=\"c\">Text &amp; more</a>", "<script>let x = 1;</script>", "</html>"),
  css: ("/* a comment */", "@media print { body { color: #333; margin: 1in 2px; } }",
    ".a > #b:hover::before { content: \"x\"; font-weight: bold !important; }"),
  c: ("/* a comment */", "#include <stdio.h>", "#define N 10",
    "static int f(const char *s, unsigned n) {", "    struct p { int x; } q = {0};",
    "    printf(\"%d\\n\", n); return sizeof(q) > 0 ? 1 : 0x2f;", "}"),
  go: ("// a comment", "package main", "import \"fmt\"", "type T struct { X int `json:\"x\"` }",
    "func main() { var x = 1.5; s := []string{\"a\"}; go f(); defer g()",
    "fmt.Println(x, s, nil, true) }"),
  sql: ("-- a comment",
    "SELECT a, COUNT(*) AS n FROM t WHERE b = 'x' AND c > 3.5 GROUP BY a ORDER BY n DESC;",
    "CREATE TABLE t (id INTEGER PRIMARY KEY, name TEXT NOT NULL);"),
  diff: ("diff --git a/x b/x", "--- a/x", "+++ b/x", "@@ -1,3 +1,3 @@", " context", "-removed",
    "+added"),
  java: ("// a comment", "package a;", "import java.util.*;", "@Override",
    "public final class A<T> implements B { private static int n = 0x1F;",
    "public void f() throws E { String s = \"x\\n\"; char c = 'c'; if (s != null) return; } }"),
  latex: ("% a comment", "\\documentclass{article}", "\\begin{document}",
    "\\section{Title} $x^2 + \\alpha$ \\textbf{b}", "\\end{document}"),
  md: ("# Heading", "*emph* **strong** `code` [link](https://x)", "- item", "> quote", "```",
    "fence", "```"),
  xml: ("<?xml version=\"1.0\"?>", "<!-- c -->", "<a b=\"c\"><![CDATA[x]]>&amp;</a>"),
  ruby: ("# a comment", "require 'x'", "class A < B", "  def f(n = 1) = \"#{n} \\n\"",
    "  attr_reader :sym", "end", "puts [1, 2.5, nil, true].map { |x| x * 2 } if __FILE__ == $0"),
  hs: ("-- a comment", "module Main where", "import Data.List", "main :: IO ()",
    "main = print (foldr (+) 0 [1, 2.5] :: Double) >> putStrLn \"x\\n\""),
)
#let grey = bytes(```
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict><key>name</key><string>Grey</string><key>settings</key><array>
<dict><key>settings</key><dict><key>foreground</key><string>#000000</string></dict></dict>
<dict><key>scope</key><string>comment</string><key>settings</key>
<dict><key>foreground</key><string>#74747c</string></dict></dict>
</array></dict></plist>
```.text)
#let lines = samples.pairs().map(((lang, ls)) => ls.map(l => raw(l, lang: lang))).flatten()
#let inline = lines.join(linebreak())

#if theme == "plain" and where == "every" {
  for (lang, ls) in samples { raw(ls.join("\n"), lang: lang, block: true) }
  for (lang, ls) in others { raw(ls.join("\n"), lang: lang, block: true) }
} else if theme == "plain" { inline } else {
  show: base.with(title: [Highlight], calibration: given)
  [#metadata(_calibration(given).ink) <highlight-ink>]
  set raw(theme: (typst: auto, "none": none, grey: grey).at(theme))
  if where == "white" { inline } else if where == "code" {
    for (lang, ls) in samples { raw(ls.join("\n"), lang: lang, block: true) }
  } else if where == "chip" { lines.map(l => chip(l, "ok")).join(" ") } else if (
    where == "callout") { callout(tone: "ok", inline) } else if where == "unit" {
    unit([Settled], "ok", [The lead.], inline)
  } else if where in ("head", "stripe") {
    let (head, row) = if where == "head" { (inline, [A]) } else { ([Code], inline) }
    sheet((1fr, auto), (head, [Amount]), row, [1])
  } else { panic("highlight.typ has no where " + where) }
}
