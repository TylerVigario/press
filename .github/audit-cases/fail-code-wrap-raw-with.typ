// A code block made through raw.with wraps as one written out does, and the audit says so.
// expect: is too long for it and wraps: echo word word
#import "/lib.typ": *
#show: brief.with(title: [Command], author: "press")

#let shell = raw.with(block: true, lang: "sh")
#shell("echo " + "word " * 40)
