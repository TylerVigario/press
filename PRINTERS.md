# Printers

press's own calibration, `calibration` in `lib/tokens.typ`, is the numbers its presets are set
for: the band at each edge of the paper a printer cannot print, the lightest ink that reads, the
palest fill that prints even and the thinnest rule that prints unbroken. Each printer the
calibration sheet, `calibration.typ`, has been printed on is recorded here, with what the sheet
read, so press's numbers can be traced to the paper they came from, and a repository calibrating
its own printer has others to compare with.

No printer is recorded yet. press's calibration is still what press used before it had a sheet:
a band of 0.48in at every edge, its own lightest ink and palest tint, and the thinnest rules it
draws.

| Printer | Mode | Printed | press | Edges: top, bottom, left, right | Ink | Fill | Rules: `rule-hair`, `rule-mid`, `slate`, `ink` |
|---|---|---|---|---|---|---|---|

## Recording a printer

Print the sheet as its first page says: on the paper the printer is used with, at Actual size,
duplex, flipping on the long edge, once at normal quality and once in economy mode. Each printing
is a row:

- **Printer:** its make and model, and nothing of where it is or whose it is.
- **Mode:** normal or economy.
- **Printed:** the date, as 2026-11-20.
- **press:** the version in the sheet's header.
- **Edges:** readings 2 and 3, the band at each edge, the larger of the front's and the back's,
  in mm: what a template's `calibration` takes as `edges`.
- **Ink:** reading 4, the lightest grey that reads, as its contrast, `6` for 6:1.
- **Fill:** reading 5, the palest grey that prints an even fill, as its contrast.
- **Rules:** reading 6, the thinnest rule that prints unbroken in each colour, in pt.

README's *Printing* says what each number sets.
