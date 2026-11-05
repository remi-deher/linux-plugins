# linux-plugins

Personal collection of shell plugins for Linux desktops, sorted by environment.

| Environment | Plugin | What it does | Status |
| --- | --- | --- | --- |
| Ryoku | [ryoku-pods](linux/ryoku/ryoku-pods) | AirPods battery, listening modes and settings in the bar | works with AirPods Pro 3; case battery unconfirmed |
| Omarchy | – | – | empty for now |

## Layout

```text
linux/<environment>/<plugin>/   one self-contained plugin per folder
mirrors.json                    plugin folder -> single-plugin repo it is published to
scripts/                        new-plugin.sh, validate-all.sh
CREDITS.md                      upstream authors and licences
```

## Installing a plugin

Ryoku and Omarchy install from a git URL only when `manifest.json` sits at the
**root** of the repository. This repo has many plugins, so install from a clone:

```bash
git clone https://github.com/remi-deher/linux-plugins
ryoku plugin add linux-plugins/linux/ryoku/ryoku-pods --bar --yes
```

Plugins listed in [`mirrors.json`](mirrors.json) are also published to their own
repository by CI, so `ryoku plugin add <mirror-url> --bar --yes` works too.

## Working here

- [AGENTS.md](AGENTS.md): conventions for contributors and AI agents.
- `scripts/new-plugin.sh ryoku <id>` scaffolds a plugin; `scripts/validate-all.sh` checks them all.
- Licence: MIT, except where a plugin's own `LICENSE` says otherwise. See [CREDITS.md](CREDITS.md).
