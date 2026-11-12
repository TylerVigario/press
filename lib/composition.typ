// press's composition vocabulary: the parts that hold a document's ideas and lay them out.

#import "tokens.typ": *
#import "parts.typ": *

// Generic by nature — a labelled bounded block, a state chip, a question awaiting its answer.

// The workhorse. A bounded unit of exactly one idea: a label to navigate by, a
// bold LEAD that is the highlight pre-made, and a body as long as the idea
// actually needs. There is no length cap on purpose — capping length lets the
// format decide what the reader is allowed to know.
// `caps` forwards to the label's `eyebrow` — see the note on it in parts.typ. This is the
// most-used call in the vocabulary, so it is where the uppercasing does the most
// damage: `unit([pH], "warn")` renders "PH" with nothing to indicate it happened. A unit is
// kept whole where it fits on a page, and let break where it is taller than one; `breakable` is
// as code()'s. One that breaks keeps its label with the lead, as a callout does. Its tone's shape
// goes before its label, as a callout's does, and `shape` changes it.
#let unit(label, tone, lead, body, caps: true, breakable: auto, shape: auto) = {
  let pair = tones.at(tone)
  context _fit("unit", breakable, b => block(width: 100%, breakable: b,
        stroke: (left: 2.5pt + pair.at(0)), fill: paper-tint, inset: (x: 8pt, y: 6.5pt))[
    #let spacing = par.spacing
    #set par(spacing: _part-gap)
    #text(size: sz.fine, block(sticky: true,
      [#_shaped("unit", tone, shape)#eyebrow(label, color: pair.at(0), caps: caps)]))
    #v(2.5pt)
    #text(size: sz.fine, weight: 700)[#lead]
    #if body != none [ #v(2.5pt) #text(size: sz.fine, _body(spacing, body)) ]
  ])
}

// A state, shown by its tone's colour and its shape: the circle is ok, the triangle warn, the
// square bad, the diamond note. Boxed, it is a pill with its label, for a legend:
// `chip([MATCHES], "ok")`. `boxed: false` sets the shape and the label alone, bold in the tone's
// colour at the size of the text around it, for a value in a table whose every cell has a state,
// where a pill in each would be too heavy: `chip([4], "ok", boxed: false)`. The legend's pills
// draw the same shapes, so a reader matches a cell to its state on a grey printout too.
// `shape` changes the tone's shape, "circle", "triangle", "square" or "diamond", and none leaves
// it out.
#let chip(label, tone, boxed: true, shape: auto) = {
  let pair = tones.at(tone)
  let shown = [#_shaped("chip", tone, shape, gap: 0.3em)#label]
  if boxed {
    box(fill: pair.at(1), stroke: 0.5pt + pair.at(0), inset: (x: 4pt, y: 2pt), radius: 1pt,
        text(size: sz.micro, weight: 700, fill: pair.at(0), shown))
  } else {
    text(weight: 700, fill: pair.at(0), shown)
  }
}

// A question with its note, under its number in a filled badge — for anything the reader must
// answer. Kept whole where it fits on a page, and let break where it is taller than one;
// `breakable` is as code()'s.
#let decision(n, q, note, color: bad, breakable: auto) = context _fit("decision", breakable,
  b => block(width: 100%, breakable: b, inset: (bottom: 5.5pt))[
  #let spacing = par.spacing
  #set par(spacing: _part-gap)
  #grid(columns: (auto, 1fr), gutter: 6pt, align: (left + top, left + top),
    box(fill: color, radius: 50%, inset: (x: 4.5pt, y: 3pt),
      text(size: sz.fine, weight: 700, fill: white)[#n]),
    [
      #text(size: sz.fine, weight: 700)[#q]
      #v(1.5pt)
      #text(size: sz.fine, fill: ink-soft, _body(spacing, note))
    ])
])

// Room for a pen: ruled paper spaces its lines 7 to 9 mm apart, and 8 mm takes ordinary
// handwriting. A blank table row is otherwise only as tall as its inset, about 3 mm.
#let _pen = 8mm

// How far below the page's top edge its text area starts, as typst places it: a relative margin
// is of the page's height, and auto is typst's 2.5/21 of the page's shorter side. Read in context.
#let _text-top() = {
  let m = page.margin
  let top = if type(m) == dictionary { m.at("top", default: auto) } else { m }
  if top == auto { 2.5 / 21 * calc.min(page.width, page.height) } else {
    // A length, a ratio or both, as one relative length.
    let top = 0% + top
    top.ratio * page.height + top.length.to-absolute()
  }
}

// The line a pen writes on, under a signature, a date or a note.
#let _hand-line = line(length: 100%, stroke: 0.5pt + ink)

// A table of any number of columns, two or twenty: `#sheet((auto, 1fr), ([Item], [Amount]), ..)`.
//
// `cols` is passed through to `table.columns` so the document keeps control of
// widths. Header row is bold on a slate tint, body rows zebra-striped.
//
// `size` exists because a fixed size pushed documents into writing their own per-cell
// wrapper just to get a different one.
//
// The header goes through `table.header`, so the PDF marks it as one, a screen reader reads it
// as the column labels rather than as data, and it repeats on every page the table spans.
// Without it a table crossing a page break leaves the reader with bare rows and no column
// labels — and on paper there is no scrolling back.
//
// A cell given as typst's `table.cell` keeps its span and its other fields, and a `table.hline`,
// `table.vline` or `table.footer` is drawn as in typst's table: a totals row is a footer,
// `table.footer(table.cell(colspan: 2)[Total], [82])`. The sheet places its cells in the order
// given, so a cell takes no `x` or `y`; rows a span ties together are kept together, as one row is.
// Under `across`, the footer closes the last column, and a line takes no `y`.
//
// A row is kept whole where it fits on a page. One that does not fit in what is left of the page
// starts the next, under the repeated header: split, the rest of it would open that page beside
// empty cells and read as a row of its own, with nothing in its first column. A row taller than a
// page splits, as it must, rather than run off the page's foot. typst knows a column's width only
// inside its cells, so each cell measures its words there, and the sheet reads the heights back
// on typst's next pass. `breakable: true` lets every row split, and `false` keeps every one
// whole, so that one taller than a page runs off its foot, as the audit then says.
//
// `blank` adds that many empty rows after the given ones, each tall enough to write in, for a
// log filled in by hand: `#sheet((auto, auto, 1fr), ([Date], [Size], [Notes]), blank: 6)`.
//
// `across` sets the sheet in that many columns, `gutter` apart, for a long, narrow list that would
// otherwise fill half the page's width: `#sheet((1fr, auto), ([Room], [Key]), across: 2, ..keys)`.
// It reads down each column, then the next, then the next page, with the header atop every column.
// typst flows the full pages, which keeps that order, but cannot balance columns, so where the sheet
// ends press splits its last rows between the columns by their measured height, not their count,
// and the columns end level, a row that wraps counted at its height. A sheet that fits on one page
// is balanced the same way.
// Each sheet's number, by which it alone reads back its cells' heights.
#let _sheets = counter("press-sheet")

#let sheet(cols, head, size: sz.micro, blank: 0, across: 1, gutter: 9pt, breakable: auto,
  ..rows) = {
  assert(type(across) == int and across >= 1,
    message: "sheet(across:) takes a number of columns, 1 or more; got " + repr(across))
  assert(breakable in (auto, true, false),
    message: "sheet(breakable:) takes auto, true or false; got " + repr(breakable))
  let inset = (x: 5pt, y: 4pt)
  let n = if type(cols) == int { cols } else { cols.len() }
  // A cell's code is set at the sheet's size, as its words are.
  let at-size(c, ..style) = {
    show raw: set text(size: size)
    set par(spacing: _part-gap)
    text(size: size, ..style, c)
  }
  let is-a(c, ..kinds) = type(c) == content and kinds.pos().contains(c.func())
  // A cell given as typst's table.cell keeps its span and its other fields, its body set at the
  // sheet's size as every cell's is. A sheet places its cells in the order given.
  let unpack(c, ..style) = if is-a(c, table.cell) {
    let fields = c.fields()
    let body = fields.remove("body")
    assert("x" not in fields and "y" not in fields, message: "a sheet places its cells in the "
      + "order given, so its table.cell takes no x or y; typst's table places a cell by position")
    (body: at-size(body, ..style), fields: fields)
  } else { (body: at-size(..style)[#c], fields: (:)) }
  let head-cells = head.map(h => {
    let (body, fields) = unpack(h, weight: 700)
    assert(fields.at("rowspan", default: 1) == 1, message: "a sheet's head is one row")
    table.cell(..fields, body)
  })
  // Each cell, with the place typst's table gives it: the next free one, along the rows, past
  // any a cell above spans down into. A span past the last column or over another cell is
  // typst's to refuse. A line or a footer of typst's table goes with the rows before it; a
  // footer closes the sheet.
  let entries = ()
  let foot = none
  let taken = (:)
  let at = 0
  let place-of(i) = str(calc.rem(i, n)) + "," + str(calc.quo(i, n))
  let given = rows.pos()
  for (i, c) in (..given, ..range(blank * n)).enumerate() {
    if i < given.len() and is-a(c, table.hline, table.vline) { entries.push((line: c)); continue }
    if i < given.len() and is-a(c, table.footer) {
      let fields = c.fields()
      let kids = fields.remove("children")
      foot = table.footer(..fields, ..kids.map(k => if is-a(k, table.hline, table.vline) { k }
        else { let (body, fields) = unpack(k); table.cell(..fields, body) }))
      continue
    }
    let (body, fields) = if i < given.len() { unpack(c) }
      else { (body: box(height: _pen - 2 * inset.y), fields: (:)) }
    while place-of(at) in taken { at += 1 }
    let (x, y) = (calc.rem(at, n), calc.quo(at, n))
    let (w, h) = (fields.at("colspan", default: 1), fields.at("rowspan", default: 1))
    for dx in range(w) { for dy in range(h) { taken.insert(place-of(at + dx + dy * n), true) } }
    entries.push((body: body, fields: fields, row: y, rows: h))
  }
  // The rows a span ties together are kept together, as one group: a group is what a row is
  // alone, kept whole where it fits on a page, and in `across`, moved between columns whole.
  let groups = ((first: 0, entries: ()),)
  let end = -1
  for e in entries {
    if "row" in e {
      if end >= 0 and e.row > end { groups.push((first: e.row, entries: ())) }
      end = calc.max(end, e.row + e.rows - 1)
    }
    groups.last().entries.push(e)
  }
  assert(across == 1 or entries.all(e => "line" not in e or e.line.func() != table.hline
      or e.line.fields().at("y", default: auto) == auto),
    message: "sheet(across:) draws a table.hline where it is given among the rows, so it takes "
      + "no y")
  // The sheet, or the part of it a column holds: `before` rows come ahead of these, so the
  // stripes run on from column to column.
  let part(cells, before: 0, last: true) = table(
    columns: cols,
    stroke: 0.4pt + rule-hair,
    inset: inset,
    fill: (_, y) => if y == 0 { slate-tint }
      else if calc.odd(y + before) { paper-tint } else { none },
    table.header(..head-cells),
    ..cells,
    ..if last and foot != none { (foot,) },
  )
  _sheets.step()
  layout(region => context {
    let id = _sheets.get().first()
    let w = (region.width - gutter * (across - 1)) / across
    let head-h = measure(block(width: w, part((), last: false))).height
    // A footer typst repeats takes its room on every page, as the header does.
    let foot-h = if foot != none and foot.fields().at("repeat", default: true) {
      measure(block(width: w, part(()))).height - head-h
    } else { 0pt }
    // Each row's tallest cell, and each span's height, as the cells measured themselves on
    // typst's last pass. On its first there are none, and every group is kept whole.
    let rows-h = (:)
    let spans-h = (:)
    if breakable == auto {
      for m in query(<press-sheet-cell>) {
        if m.value.sheet == id {
          let (into, key) = if m.value.rows == 1 { (rows-h, str(m.value.row)) }
            else { (spans-h, str(m.value.group)) }
          let h = calc.max(into.at(key, default: 0pt), m.value.height + 2 * inset.y * m.value.rows)
          if m.value.rows == 1 { rows-h.insert(key, h) } else { spans-h.insert(key, h) }
        }
      }
    }
    // A group splits where it is taller than a page holds under the header: its rows' tallest
    // cells stacked, or a span, whichever is taller. Measured, as inside units(), the page has
    // no end, and every group fits. The measuring is placed, so it takes no room.
    let cells = groups.enumerate().map(((g, group)) => {
      let placed = group.entries.filter(e => "row" in e)
      let span = placed.fold(group.first, (a, e) => calc.max(a, e.row + e.rows)) - group.first
      let tall = calc.max(spans-h.at(str(g), default: 0pt),
        range(group.first, group.first + span).map(r =>
          rows-h.at(str(r), default: 2 * inset.y)).sum(default: 0pt))
      let over = tall > region.height - head-h - foot-h
      group.entries.map(e => {
        if "line" in e { return e.line }
        let fields = e.fields
        let own = fields.remove("breakable", default: auto)
        let b = if own != auto { own } else if breakable != auto { breakable } else { over }
        table.cell(..fields, breakable: b, {
          if breakable == auto {
            place(layout(s => [#metadata((sheet: id, group: g, row: e.row, rows: e.rows,
              height: measure(block(width: s.width, e.body)).height))<press-sheet-cell>]))
          }
          e.body
        })
      })
    })
    if across == 1 or entries.len() == 0 { part(cells.flatten()) } else {
      let lines = cells
      let firsts = groups.map(g => g.first)
      let tall = lines.enumerate().map(((i, l)) =>
        measure(block(width: w, part(l, last: i == lines.len() - 1))).height - head-h)
      // A column's height on a full page, and on the page the sheet starts on, what is left of it.
      // Measured, as inside units(), the height has no end, and the sheet is one page.
      let full = region.height
      let first = if full.pt() == calc.inf { full } else {
        full - (here().position().y - _text-top())
      }

      // The page each row lands on, filling as typst's columns do: a column takes rows while they
      // fit, and the sheet moves on from a column too short for its header and first row. A row
      // taller than a whole page's column goes where it is, as typst puts it there: split, or
      // under breakable: false whole and past the column's foot.
      let room(leaf) = (if leaf == 0 { first } else { full }) - head-h
      let leaf = 0
      let col = 0
      let used = 0pt
      let on = ()
      for h in tall {
        while used + h > room(leaf) and not (used == 0pt and leaf > 0) {
          used = 0pt
          col += 1
          if col == across { col = 0; leaf += 1 }
        }
        on.push(leaf)
        used += h
      }

      // The last page's rows, shared between its columns by height. `most` is the shortest the
      // tallest column can be, found by halving between what an even share would be and all of
      // them. Then each column takes rows until it holds its share of what is left, never past
      // `most`, so where the rows cannot come out even, an earlier column is the longer.
      let t = on.position(p => p == leaf)
      let rest = tall.slice(t)
      let total = rest.sum()
      let slack = 0.01pt
      let needs(most) = {
        let count = 1
        let held = 0pt
        for h in rest {
          if held > 0pt and held + h > most + slack { count += 1; held = 0pt }
          held += h
        }
        count
      }
      let low = calc.max(..rest, total / across)
      let most = total
      for _ in range(24) {
        let mid = (low + most) / 2
        if needs(mid) <= across { most = mid } else { low = mid }
      }
      let shares = ()
      let i = 0
      for c in range(across) {
        let share = rest.slice(i).sum(default: 0pt) / (across - c)
        let held = 0pt
        let from = i
        while i < rest.len() and (c == across - 1
            or (held < share - slack and held + rest.at(i) <= most + slack)) {
          held += rest.at(i)
          i += 1
        }
        shares.push(range(from, i))
      }
      let fits = shares.all(s => s.map(i => rest.at(i)).sum(default: 0pt) <= room(leaf) + slack)

      let flowed = if t > 0 { (part(lines.slice(0, t).flatten(), last: false), colbreak()) }
        else { () }
      let ending = if not fits { (part(lines.slice(t).flatten(), before: firsts.at(t)),) } else {
        let held = shares.filter(s => s.len() > 0)
        held.enumerate().map(((k, s)) =>
          part(s.map(i => lines.at(t + i)).flatten(), before: firsts.at(t + s.first()),
            last: k == held.len() - 1)
        ).intersperse(colbreak())
      }
      columns(across, gutter: gutter, (..flowed, ..ending).join())
    }
  })
}

// Lines to write on by hand, `n` of them, `pitch` apart, each after `label` where one is given:
// `#writein(3, label: [date])` for dated notes. They print; a PDF viewer cannot fill them, since
// typst writes no PDF form fields.
#let writein(n, label: none, pitch: _pen) = {
  assert(type(n) == int and n > 0, message: "writein() needs a number of lines, 1 or more")
  let row = if label == none { (_hand-line,) } else {
    (text(size: sz.micro, fill: ink-soft, label), _hand-line)
  }
  grid(columns: if label == none { (1fr,) } else { (auto, 1fr) },
    rows: pitch, column-gutter: 6pt, align: bottom,
    ..range(n).map(_ => row).flatten())
}

// A box to tick by hand, sized in em so it follows the text it sits in: inline, in a sheet()
// cell, or as a list's marker, where the list gives a checklist its hanging indent. As a marker it
// is wider than a bullet, so the list sets its text further from it, `body-indent: 0.6em`.
// It is centred on the face's x-height, measured, so it sits with the lowercase beside it in any
// face. press draws it because ☐ is in no vendored face. `checked: true` marks it with an X, as
// tick() does, for a copy filled in ahead of time. The audit does not count an empty box, unlike
// an open item: on paper, an empty box is what the reader is there to fill.
//
//   #set list(marker: checkbox(), body-indent: 0.6em)
//   - Shut the water off at the street.
#let checkbox(checked: false, size: 0.7em, stroke: 0.6pt + ink, radius: 1pt) = context {
  let x = measure(text(top-edge: "x-height", bottom-edge: "baseline")[x]).height
  box(width: size, height: size, baseline: size / 2 - x / 2, stroke: stroke, radius: radius,
    if checked { place(center + horizon,
      text(size: size, weight: 700, top-edge: "cap-height", bottom-edge: "baseline")[X]) })
}

// Where a document is signed, with its closing (`closing: [Sincerely,]`) kept on the same page, so
// a page break never strands it. By default, space for an ink signature over a line with the
// signer's name beneath, and beside it a line to date by hand (`dated: false` leaves that out).
// For a document sent as a file, `signed: false` is a typed sign-off: the name alone.
//
// `name` is who signs, the document's author unless it is given. A document several people sign
// calls it once for each, with their names, and places them itself. With its date line beside, a
// signature is 4.4in wide, too wide for two side by side, so the arrangement is the document's:
//
//   `width` is the ink line's length, 2.6in by default. A relative width is of the room the line
//   has, which beside a date line is what the date leaves: `width: 100%` fills a grid's cell.
//   `dated` is true for the date line beside the name's, "below" for it under the name, with a
//   pen's room above it, or false for none. The date line is 1.4in either way, so it never reads
//   as a second line to sign.
//
// Two signers side by side, each with a date, fit any of press's measures:
//
//   #grid(columns: (1fr, 1fr), gutter: 22pt,
//     signature(name: [Pat Example], width: 100%, dated: "below"),
//     signature(name: [Sam Example], width: 100%, dated: "below"))
//
//   #signature(name: [Pat Example])
//   #signature(name: [Sam Example], dated: false)
#let signature(
  name: auto, closing: none, signed: true, dated: true, width: 2.6in, words: (date: [Date]),
) = block(breakable: false, context {
  // An unknown arrangement fails rather than falling through to one that looks deliberate.
  assert(dated in (true, false, "below"),
    message: "signature(dated:) expects true, false or \"below\"; got " + repr(dated))
  assert(type(width) in (length, ratio, relative),
    message: "signature(width:) takes a length or a relative width: width: 2.9in, width: 100%")
  let name = if name == auto { _writer(what: "signature(), given no name,") } else { name }
  set par(spacing: _part-gap)
  if closing != none { closing }
  if not signed {
    if closing != none { parbreak() }
    name
  } else {
    let slot(caption) = stack(spacing: 5pt, _hand-line, caption)
    let date = slot(_words("signature", words, "date").date)
    v(0.55in)
    layout(size => {
      // The room the ink line has: all of it, or what a date line beside it leaves.
      let room = if dated == true { size.width - 1.8in } else { size.width }
      let ink = if type(width) == ratio { width * room }
        else if type(width) == relative { width.ratio * room + width.length.to-absolute() }
        else { width.to-absolute() }
      if dated == "below" {
        stack(block(width: ink, slot(name)), _pen, block(width: 1.4in, date))
      } else {
        grid(columns: if dated { (ink, 0.4in, 1.4in) } else { (ink,) },
          slot(name), ..if dated { ([], date) } else { () })
      }
    })
  }
})

// Lay out a set of units. This sets no page; it owns only how a GROUP packs,
// which is the one thing every document was re-deriving by hand.
//
//   "stacks"  two columns filled independently and balanced by MEASURED height.
//             Nothing is padded to match a neighbour, which is the failure of a
//             row grid: a row is as tall as its tallest cell, so a short unit
//             beside a long one leaves the gap under it.
//   "grid"    row-major cells. Keeps units aligned across a row — correct when
//             the pairing means something, and the source of that gap when it
//             does not.
//   "single"  one column, full width.
//
// Balancing measures at the real column width inside `layout`, because a unit's
// height depends on where it wraps. Counting source lines guesses at that and is
// wrong wherever prose wraps differently from markup.
#let units(..items, pack: "stacks", gutter: 9pt, spacing: 6pt) = {
  // Fail on an unknown value rather than falling through. `pack: "stack"` would
  // otherwise render the default and look deliberate, which is the failure mode
  // press is meant to make loud.
  assert(pack in ("stacks", "grid", "single"),
         message: "units(pack:) expects \"stacks\", \"grid\" or \"single\"; got \"" + pack + "\"")
  let us = items.pos()
  // One column of units, `spacing` apart. Its gutter is the gap, as it is under "grid": units set
  // one after another as blocks would take the paragraph gap around each as well.
  let stack(col) = grid(columns: (1fr,), row-gutter: spacing, ..col)

  if us.len() == 0 { return }
  if pack == "single" { return stack(us) }
  if pack == "grid" {
    return grid(columns: (1fr, 1fr), gutter: gutter, row-gutter: spacing, ..us)
  }

  // pack == "stacks", guaranteed by the assert above.
  layout(size => {
    let w = (size.width - gutter) / 2
    let left = ()
    let right = ()
    let hl = 0pt
    let hr = 0pt
    // A column is as tall as its units and the gaps between them.
    for u in us {
      let h = measure(box(width: w, u)).height
      if hl <= hr {
        hl += h + if left.len() > 0 { spacing } else { 0pt }
        left.push(u)
      } else {
        hr += h + if right.len() > 0 { spacing } else { 0pt }
        right.push(u)
      }
    }
    grid(columns: (1fr, 1fr), gutter: gutter, align: top,
         stack(left), stack(right))
  })
}
