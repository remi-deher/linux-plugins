# Credits

| Plugin | Based on | Author | Licence |
| --- | --- | --- | --- |
| `linux/ryoku/ryoku-pods` | [omarchy-pods](https://github.com/thisisgm/omarchy-pods) (commit `fff7fec`): original panel design, `Model.js`, patched daemon | GM (`thisisgm`), MIT | MIT |
| `linux/ryoku/ryoku-pods/daemon` (shipped, modified copy) | [librepods](https://github.com/kavishdevar/librepods) by way of GM's fork [omarchy-pods](https://github.com/thisisgm/omarchy-pods) (`fff7fec`): AirPods AAP protocol over L2CAP and BLE advertisements, the daemon itself | Kavish Devar (librepods), GM (fork), modified by Rémi Deher (conversation-awareness volume), GPLv3 | GPLv3 (`daemon/LICENSE`) |
| `linux/ryoku/ryoku-pods/daemon/thirdparty/QR-Code-generator` | [QR Code generator library](https://github.com/nayuki/QR-Code-generator) | Project Nayuki | MIT (notice in the source files) |
| `linux/ryoku/proton-vpn` | [OmaProton VPN](https://github.com/grichard99/omaproton-vpn) (v1.4.9): service logic, CLI output parsing, Python helpers (`bin/ryoproton-*`), world map and traffic components, `World.js` (Natural Earth outline, public domain) | grichard99, MIT | MIT |

The shipped daemon is GPLv3 and stays under that licence; the plugin's own files are MIT. Apple's SF Symbols font that the fork bundles is not redistributable and is left out.

Keep the copyright line of every upstream author in the plugin's own `LICENSE`.
Add a row here whenever a plugin derives from someone else's work.
