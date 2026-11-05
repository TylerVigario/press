// A line of a code block too long for it wraps, and copies with a break in it: the audit says so.
// expect: is too long for it and wraps: rsync -a --delete
#import "/lib.typ": *
#show: brief.with(title: [Nightly backup], author: "press")

The copy runs each night from the office server:

```sh
rsync -a --delete --exclude '.cache/' /srv/photos/ backup@archive.example.org:/srv/backups/photos/
ls -la /srv/backups
```
