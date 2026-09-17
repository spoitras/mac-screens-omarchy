// avahi-browse escapes each non-alphanumeric byte of a service name as
// \DDD (decimal, not octal — e.g. a space is "\032"). A name with non-ASCII
// characters, like a curly apostrophe in "Sylvain's Mac mini", comes through
// as its raw UTF-8 bytes each escaped separately ("\226\128\153"), so the
// escapes have to be collected into a byte array and UTF-8 decoded as a
// whole rather than converted one \DDD at a time.
function decodeAvahiName(raw) {
  if (!raw) return ""
  var text = String(raw)
  var bytes = []
  for (var i = 0; i < text.length; i++) {
    if (text.charAt(i) === "\\" && /^\d{3}$/.test(text.substr(i + 1, 3))) {
      bytes.push(parseInt(text.substr(i + 1, 3), 10))
      i += 3
    } else {
      bytes.push(text.charCodeAt(i))
    }
  }
  return utf8Decode(bytes)
}

function utf8Decode(bytes) {
  var out = ""
  var i = 0
  while (i < bytes.length) {
    var b0 = bytes[i]
    if (b0 < 0x80) {
      out += String.fromCharCode(b0)
      i += 1
    } else if ((b0 & 0xe0) === 0xc0 && i + 1 < bytes.length) {
      out += String.fromCharCode(((b0 & 0x1f) << 6) | (bytes[i + 1] & 0x3f))
      i += 2
    } else if ((b0 & 0xf0) === 0xe0 && i + 2 < bytes.length) {
      out += String.fromCharCode(
        ((b0 & 0x0f) << 12) | ((bytes[i + 1] & 0x3f) << 6) | (bytes[i + 2] & 0x3f)
      )
      i += 3
    } else if ((b0 & 0xf8) === 0xf0 && i + 3 < bytes.length) {
      var cp = ((b0 & 0x07) << 18) | ((bytes[i + 1] & 0x3f) << 12)
        | ((bytes[i + 2] & 0x3f) << 6) | (bytes[i + 3] & 0x3f)
      cp -= 0x10000
      out += String.fromCharCode(0xd800 + (cp >> 10), 0xdc00 + (cp & 0x3ff))
      i += 4
    } else {
      out += String.fromCharCode(b0)
      i += 1
    }
  }
  return out
}

// Parses `avahi-browse -r -p -t _rfb._tcp` output. Resolved records start
// with "=" and look like:
//   =;iface;protocol;name;type;domain;hostname;address;port;txt
// IPv4 and IPv6 records both resolve for the same host; IPv6 is dropped so
// dual-stack Macs don't produce duplicate rows, and connecting by the
// already-resolved IPv4 address (rather than the .local hostname) avoids
// mDNS resolution stalls on first connect.
function parseBrowseOutput(text) {
  var lines = String(text || "").split("\n")
  var byAddress = {}

  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (line.charAt(0) !== "=") continue

    var fields = line.split(";")
    if (fields.length < 9) continue
    if (fields[2] !== "IPv4") continue

    var address = fields[7]
    var port = parseInt(fields[8], 10)
    if (!address || !port) continue

    byAddress[address] = {
      name: decodeAvahiName(fields[3]) || address,
      hostname: fields[6],
      address: address,
      port: port
    }
  }

  var rows = []
  for (var key in byAddress) rows.push(byAddress[key])
  rows.sort(function(a, b) { return a.name.localeCompare(b.name) })
  return rows
}

if (typeof module !== "undefined") {
  module.exports = {
    decodeAvahiName: decodeAvahiName,
    parseBrowseOutput: parseBrowseOutput
  }
}
