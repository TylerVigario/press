// Starter skeleton for a VTS printable. COPY this — do not import it.
// Composition belongs to the document; only the vocabulary is shared.
//
//   typst init --package-path vendor/press/packages @vts/press:0.1.0 <name>
//
// (that path is from a repo consuming press as a submodule at vendor/press;
//  from inside the press repo itself it is just --package-path packages)
//
// or just copy this file to docs/<name>.typ and start deleting.
//
// ---------------------------------------------------------------------------
// The conventions this skeleton encodes. They are what make a document
// scannable; the tokens alone will not do it.
//
//   1. MEAT FIRST. Whatever the reader must act on goes at the top. Attention
//      is spent before it is earned back — do not make them read design detail
//      to reach a decision.
//   2. ONE IDEA PER UNIT, opened by a bold LEAD. That lead is the highlight,
//      pre-made, so nobody has to reach for a marker.
//   3. UNITS ARE SELF-CONTAINED. Nothing may assume the unit above it was
//      read. Sections get read out of order and returned to weeks later.
//   4. BANDS CARRY A ROLE — decide / design / reference. Skipping a section
//      should be a deliberate choice, not something discovered afterwards.
//   5. COLOUR IS STATE, never decoration, and it gets a legend.
//   6. NO LENGTH CAP. If a unit needs depth, give it depth, or push the depth
//      to a second layer — but never delete it to fit a layout. If it does not
//      fit, the layout is what changes.
// ---------------------------------------------------------------------------

#import "@vts/press:0.1.0": *

#set page(..card, footer: context {
  set text(size: sz.micro, fill: ink-faint)
  grid(columns: (1fr, auto),
    align(left)[Document title · status],
    align(right)[#updated() · #counter(page).display("1 / 1", both: true)])
})
#set text(font: face-text, size: sz.small, fill: ink, lang: "en")
#set par(leading: 0.52em, spacing: 0.55em)
#set list(indent: 0.65em, body-indent: 0.34em, spacing: 0.32em)
#show raw: set text(font: face-mono, size: sz.micro)
// Code blocks get press's treatment: one shaded, bordered block per listing,
// commands as plain lines. Delete this line for a document that wants its own —
// press supplies the treatment, the document decides to install it.
#show raw.where(block: true): code

// ---- Header + legend ----
#grid(columns: (auto, 1fr), align: (left + bottom, right + bottom),
  text(font: face-display, size: sz.title, weight: 700)[Document Title],
  text(size: sz.fine, fill: ink-soft)[scope · date])
#v(-3pt)
#line(length: 100%, stroke: 2pt + slate)
#v(4pt)
#grid(columns: (auto, 1fr), align: (left + horizon, right + horizon),
  text(size: sz.micro, fill: ink-faint)[Colour is state. Bands carry a role — skip on purpose.],
  align(right)[#chip([SETTLED], "ok") #h(3pt) #chip([CONDITIONAL], "warn") #h(3pt) #chip([DECIDE], "bad")])
#v(7pt)

// ---- Meat first ----
#band-strong([What the reader must act on], "decide — start here", color: bad)

#grid(columns: (1fr, 1fr), gutter: 9pt,
  unit([First thing], "bad")[The lead states the point outright.][
    The body carries as much as the idea needs. No cap.
  ],
  unit([Second thing], "warn")[A conditional — true only in some case.][
    Say which case, in the body.
  ],
)
#v(8pt)

// ---- Design ----
#band-strong([How it works], "design")

#grid(columns: (1fr, 1fr), gutter: 9pt, row-gutter: 6pt,
  unit([A property], "ok")[Settled, no action needed.][Detail here.],
  unit([Another property], "note")[Neutral statement of fact.][Detail here.],
)
#v(8pt)

// ---- Reference ----
#band-strong([Reference — skip unless you need it], "reference", color: steel)

#matrix(
  ([Axis], [Consequence]),
  [Something], [What follows from it.],
)

#stamp[Status line — what this document is, and is not.]
