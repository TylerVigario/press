# shellcheck shell=sh
# word-box.sh — where a word is on the page, read from pdftotext -bbox. Sourced by the CI checks
# that measure a word's box, so each reads the boxes the same way:
#
#   . .github/word-box.sh
#   pdftotext -bbox probe.pdf boxes.html
#   word_box boxes.html Bodylabel
#
# A word is matched whole: pdftotext puts each in a <word> element of its own, so ">Bodylabel<"
# is that word and not a longer one beginning with it. A word not on the page prints nothing, so
# a check fails on an empty value rather than measuring nothing.

# word_boxes <boxes.html> <word>: each box drawn for the word, one to a line, as xMin yMin xMax
# yMax in points from the page's top left.
word_boxes() {
    awk -v w="$2" 'index($0, ">" w "<") {
        split("xMin yMin xMax yMax", key, " ")
        line = ""
        for (i = 1; i <= 4; i++) {
            match($0, key[i] "=\"[0-9.]+\"")
            line = line (i > 1 ? " " : "") substr($0, RSTART + 6, RLENGTH - 7)
        }
        print line }' "$1"
}

# word_box <boxes.html> <word>: the first of them.
word_box() { word_boxes "$1" "$2" | head -n 1; }
