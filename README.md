# Mac Screens for Omarchy

A bar widget for [Omarchy](https://omarchy.org/) that finds Macs advertising
**Screen Sharing** on your LAN and connects to them with
[NoMachine](https://www.nomachine.com/) for a fast, low-latency remote
desktop session.

```
[bar icon] ──click──► avahi-browse (_rfb._tcp) ──► dropdown of Macs ──click──► nxplayer --session "Connection to <ip>.nxs"
```

## How it works

macOS Screen Sharing advertises itself over mDNS/Bonjour as `_rfb._tcp`,
which is the same protocol Linux's Avahi speaks — no extra service or
polling infrastructure needed. Clicking the bar icon runs
`avahi-browse -r -p -t _rfb._tcp`, decodes each Mac's Bonjour name (including
proper UTF-8 handling for names with non-ASCII characters, like curly
apostrophes), and lists every Mac found, refreshing every 15 seconds while
the dropdown is open.

Note this only uses Screen Sharing for *discovery* — the actual remote
desktop session runs over NoMachine (NX protocol, port 4000), which is a
separate app you install on the Mac alongside (or instead of using) Screen
Sharing.

Clicking a Mac in the list launches NoMachine's client, `nxplayer`, against
its already-resolved IP address. Unlike Remmina, `nxplayer` has no
quickconnect flag — it only knows how to open a saved `.nxs` connection
file via `--session`. NoMachine's own connection wizard saves new
connections by default as:

```
~/Documents/NoMachine/Connection to <ip>.nxs
```

The plugin looks for a file at that exact path for the Mac you clicked:

- **If found**, it launches straight into the session:
  `nxplayer --session "~/Documents/NoMachine/Connection to <ip>.nxs"`
- **If not found** (first time connecting to that Mac), it opens
  `nxplayer --wizard` instead so you can create the connection. Point it at
  the IP address shown under the Mac's name in the dropdown, and **save it
  with the default name NoMachine suggests** (don't rename it) — every
  click after that will auto-launch it.

## Install

```sh
git clone https://github.com/spoitras/mac-screens-omarchy.git \
  ~/.config/omarchy/plugins/syl.mac-screens

omarchy bar put syl.mac-screens --section right
```

(Rename the target directory to `<your-username>.mac-screens` if you'd like
the plugin ID to match your own username, matching Omarchy's convention for
user-owned plugins — the directory name is what Omarchy treats as the ID.)

### Dependencies

```sh
yay -S nomachine
```

`nomachine` (the official client, from the AUR) installs `nxplayer` to
`/usr/NX/bin/nxplayer`, which needs to be on `PATH`.

You'll also need the **NoMachine server** app installed and running on each
Mac Mini — it's a separate download from
[nomachine.com](https://www.nomachine.com/download), not something bundled
with macOS the way Screen Sharing is. Screen Sharing itself can stay
enabled; it's only used here for LAN discovery, not for the actual session.

## Known issue: first connection to a headless Mac times out

If the Mac has no physical display attached, the OS has to spin up a
virtual display/WindowServer session on the very first remote connection,
which can lose the race against the client's connection timeout — the
first attempt times out right after you enter your password, and the
immediate retry succeeds because the session is already warm. This applied
to the previous Remmina/Screen-Sharing setup; it's not yet confirmed
whether NoMachine sessions hit the same issue against a headless Mac.

The real fix is a cheap HDMI dummy plug / EDID-emulator dongle on the Mac,
which keeps a "real" display always active so the OS never needs to create
one on demand.

## License

MIT — see [LICENSE](LICENSE).
