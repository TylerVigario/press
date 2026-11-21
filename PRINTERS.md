# Printers

press's own calibration, `calibration` in `lib/tokens.typ`, is the numbers its presets are set
for: the band at each edge of the paper a printer cannot print, the lightest ink that reads, the
palest fill that prints even and the thinnest rule that prints unbroken. Each printer the
calibration sheet, `calibration.typ`, has been printed on for press is recorded in
[`printers.csv`](printers.csv), with what the sheet read, so press's numbers can be traced to the
paper they came from, and a repository calibrating its own printer has others to compare with.

press's own calibration is the median, number by number, of the printers recorded here at normal
quality, each by its latest printing, and a document takes any one of them, or the median of
those printed in economy mode, through `printer()`, as README's *Printing* says. No printer is
recorded yet, so press's calibration is still what press used before it had a sheet: a band of
0.48in at every edge, its own lightest ink and palest tint, and the thinnest rules it draws.

## Recording a printer

Print the sheet as its first page says: on the paper the printer is used with, at Actual size,
duplex, flipping on the long edge, once at normal quality and once in economy mode. Each printing
is a row of `printers.csv`, its columns in this order:

- `printer`: its make and model, and nothing of where it is or whose it is.
- `mode`: `normal` or `economy`.
- `printed`: the date, as `2026-11-20`.
- `press`: the version in the sheet's header.
- `edge-top-mm`, `edge-bottom-mm`, `edge-left-mm`, `edge-right-mm`: readings 2 and 3, the band
  at each edge, the larger of the front's and the back's, in mm: what a template's `calibration`
  takes as `edges`.
- `ink`: reading 4, the lightest grey that reads, as its contrast, `6` for 6:1.
- `fill`: reading 5, the palest grey that prints an even fill, as its contrast.
- `rule-hair-pt`, `rule-mid-pt`, `rule-slate-pt`, `rule-ink-pt`: reading 6, the thinnest rule
  that prints unbroken in each of `rule-hair`, `rule-mid`, `slate` and `ink`, in pt.

Each number is written bare, without its unit: `4.5`, not `4.5mm`, and a make and model with a
comma in it is quoted, `"Make, Model"`. A printer printed again is a row more: its latest printing
in each mode is the one press takes, a later row taking a date it shares, and the rows before it
stay as its history. A row that is not as this says stops every build that imports press,
naming the row. README's *Printing* says what each number sets.
