# linux-plugins

Personal collection of shell plugins for Linux desktops, sorted by environment.

| Environment | Plugin | What it does | Status |
| --- | --- | --- | --- |
| Ryoku | [ryoku-pods](linux/ryoku/ryoku-pods) | AirPods battery, listening modes and settings in the bar | works with AirPods Pro 3; case battery unconfirmed |
| Omarchy | – | – | empty for now |

## Layout

```text
linux/<environment>/<plugin>/   one self-contained plugin per folder
scripts/                        new-plugin.sh, validate-all.sh, bump-versions.sh, mirror.sh
CREDITS.md                      upstream authors and licences
```

## Installing a plugin

Ryoku and Omarchy install from a git URL only when `manifest.json` sits at the
**root** of the repository. This repo has many plugins, so install from a clone:

```bash
git clone https://github.com/remi-deher/linux-plugins
ryoku plugin add linux-plugins/linux/ryoku/ryoku-pods --bar --yes
```

Every plugin is also published by CI to its own read-only repository, named after its
folder (`github.com/<owner>/<plugin>`), so `ryoku plugin add <mirror-url> --bar --yes` works too.

## Publication flow

This repository is the only place anyone works in: `main` takes pull requests only, and the
mirrors take nothing but CI.

1. `scripts/new-plugin.sh ryoku <id>`, then develop in `linux/ryoku/<id>/`.
2. Open a PR. `validate` checks the plugin, `version` raises its manifest version (label the PR
   `bump:minor` or `bump:major` for more than a patch), and `mirror` prints what merging would do.
3. Merge. `mirror` creates `<owner>/<id>` the first time (public, read-only), pushes the plugin
   there, tags `v<version>` and adds the protection rulesets. Nothing else to configure.

A plugin's manifest `id` must equal its folder name. Removing a plugin folder never deletes
its mirror: delete that repository by hand if you want it gone.

## Working here

- [AGENTS.md](AGENTS.md): conventions for contributors and AI agents.
- `scripts/new-plugin.sh ryoku <id>` scaffolds a plugin; `scripts/validate-all.sh` checks them all.
- Licence: MIT, except where a plugin's own `LICENSE` says otherwise. See [CREDITS.md](CREDITS.md).
