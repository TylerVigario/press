// Two long code blocks under brief, for code-break.sh: the first opts in to breaking across the
// page, as parts.typ shows a document doing for one block, and the second does not.
#import "/lib.typ": *

#show: brief.with(title: [Probe], author: "press")

#lorem(300)

#[
  #show raw.where(block: true): it => code(it, breakable: true)
```sh
echo opted 0
echo opted 1
echo opted 2
echo opted 3
echo opted 4
echo opted 5
echo opted 6
echo opted 7
echo opted 8
echo opted 9
echo opted 10
echo opted 11
echo opted 12
echo opted 13
echo opted 14
echo opted 15
echo opted 16
echo opted 17
echo opted 18
echo opted 19
echo opted 20
echo opted 21
echo opted 22
echo opted 23
echo opted 24
echo opted 25
echo opted 26
echo opted 27
echo opted 28
echo opted 29
echo opted 30
echo opted 31
echo opted 32
echo opted 33
echo opted 34
echo opted 35
echo opted 36
echo opted 37
echo opted 38
echo opted 39
echo opted 40
echo opted 41
echo opted 42
echo opted 43
echo opted 44
echo opted 45
echo opted 46
echo opted 47
echo opted 48
echo opted 49
echo opted 50
echo opted 51
echo opted 52
echo opted 53
echo opted 54
echo opted 55
echo opted 56
echo opted 57
echo opted 58
echo opted 59
```
]

#lorem(300)

```sh
echo whole 0
echo whole 1
echo whole 2
echo whole 3
echo whole 4
echo whole 5
echo whole 6
echo whole 7
echo whole 8
echo whole 9
echo whole 10
echo whole 11
echo whole 12
echo whole 13
echo whole 14
echo whole 15
echo whole 16
echo whole 17
echo whole 18
echo whole 19
echo whole 20
echo whole 21
echo whole 22
echo whole 23
echo whole 24
echo whole 25
echo whole 26
echo whole 27
echo whole 28
echo whole 29
echo whole 30
echo whole 31
echo whole 32
echo whole 33
echo whole 34
echo whole 35
echo whole 36
echo whole 37
echo whole 38
echo whole 39
echo whole 40
echo whole 41
echo whole 42
echo whole 43
echo whole 44
echo whole 45
echo whole 46
echo whole 47
echo whole 48
echo whole 49
echo whole 50
echo whole 51
echo whole 52
echo whole 53
echo whole 54
echo whole 55
echo whole 56
echo whole 57
echo whole 58
echo whole 59
```
