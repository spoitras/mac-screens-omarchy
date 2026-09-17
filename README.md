# Mac Screens for Omarchy

A bar widget for [Omarchy](https://omarchy.org/) that finds Macs advertising
**Screen Sharing** on your LAN and connects to them with
[Remmina](https://remmina.org/) — a lightweight, no-config alternative to
typing `vnc://` URLs by hand.

```
[bar icon] ──click──► avahi-browse (_rfb._tcp) ──► dropdown of Macs ──click──► remmina -c vnc://<ip>:<port>
```

## How it works

macOS Screen Sharing advertises itself over mDNS/Bonjour as `_rfb._tcp`,
which is the same protocol Linux's Avahi speaks — no extra service or
polling infrastructure needed. Clicking the bar icon runs
`avahi-browse -r -p -t _rfb._tcp`, decodes each Mac's Bonjour name (including
proper UTF-8 handling for names with non-ASCII characters, like curly
apostrophes), and lists every Mac found, refreshing every 15 seconds while
the dropdown is open. Clicking a Mac in the list launches Remmina against
its already-resolved IP address directly (not its `.local` hostname, which
avoids an mDNS resolution stall on the first connection).

Remmina's VNC plugin automatically negotiates Apple's security type 30
(the same Diffie-Hellman based auth Screen Sharing itself uses), so you log
in with the Mac's actual user account name and password — no separate VNC
password to set up.

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
omarchy pkg add remmina libvncserver
```

`libvncserver` isn't pulled in automatically as a dependency of `remmina`
even though its VNC plugin (`remmina-plugin-vnc.so`) requires
`libvncclient.so.1` to load at all — without it, Remmina has no VNC support.

## Known issue: first connection to a headless Mac times out

If the Mac has no physical display attached, `screensharingd` has to spin up
a virtual display/WindowServer session on the very first Screen Sharing
connection, which often loses the race against the VNC client's connection
timeout — the first attempt times out right after you enter your password,
and the immediate retry succeeds because the session is already warm.

The real fix is a cheap HDMI dummy plug / EDID-emulator dongle on the Mac,
which keeps a "real" display always active so `screensharingd` never needs
to create one on demand.

## License

MIT — see [LICENSE](LICENSE).
