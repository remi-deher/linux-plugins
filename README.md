# linux-plugins

Personal collection of shell plugins for Linux desktops, sorted by environment.

<!-- plugins:start -->
| Plugin | Environment | Version | Status | What it does |
| --- | --- | --- | --- | --- |
| [ryoku-pods](linux/ryoku/ryoku-pods) | ryoku | 0.2.0 | experimental | AirPods in the Ryoku bar: per-pod and case battery, listening mode, adaptive noise level, conversation awareness, one-bud ANC and ear detection. |
<!-- plugins:end -->

Omarchy: nothing yet. The table above is generated from the manifests (`scripts/gen-index.sh`).

## Layout

```text
linux/<environment>/<plugin>/   one self-contained plugin per folder
scripts/                        new-plugin.sh, validate-all.sh, gen-index.sh, bump-versions.sh, mirror.sh
plugins.json                    generated index of the plugins
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

1. `scripts/new-plugin.sh ryoku <id>`, then develop in `linux/ryoku/<id>/`. A new plugin is a
   `draft`: it is validated but never published.
2. Open a PR. `validate` checks the plugin, `version` raises its manifest version (label the PR
   `bump:minor` or `bump:major` for more than a patch) and refreshes the index, and `mirror`
   prints what merging would do.
3. To publish, set `"status": "experimental"` (or `"stable"`) in the manifest and merge. `mirror`
   creates `<owner>/<id>` the first time (public, read-only, issues off), pushes the plugin
   there, tags `v<version>`, sets the topics and adds the protection rulesets.

Lifecycle, from the manifest `status`: `draft` (not published) → `experimental` / `stable`
(mirrored) → `deprecated` (mirrored, flagged in the description) → `archived` (mirror archived).
A plugin folder is never deleted: archive it, or for a rename add `"replaces": "<old-id>"` to the
new manifest and the old mirror is archived with a pointer to the new one. Mirrors are never
deleted by CI. A mirror that diverged from the source is not overwritten; rerun the `mirror`
workflow manually with `force`.

## Working here

- [AGENTS.md](AGENTS.md): conventions for contributors and AI agents.
- `scripts/new-plugin.sh ryoku <id>` scaffolds a plugin; `scripts/validate-all.sh` checks them all.
- Licence: MIT, except where a plugin's own `LICENSE` says otherwise. See [CREDITS.md](CREDITS.md).
