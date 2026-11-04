// An addendum in a sheet's row and one in body text, for addendum-size.sh.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

#sheet((auto, 1fr), ([When], [What]),
  [2026-10-01], [Sheetentry
    #addendum([2026-10-20], label: [Sheetlabel], caps: false)[Sheetnote]])

Bodyentry
#addendum([2026-10-21], label: [Bodylabel], caps: false)[Bodynote]
