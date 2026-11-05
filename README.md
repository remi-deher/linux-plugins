# linux-plugins

Personal collection of shell plugins for Linux desktops, sorted by environment.

<!-- plugins:start -->
| Plugin | Environment | Version | Status | What it does |
| --- | --- | --- | --- | --- |
| [ryoku-pods](linux/ryoku/ryoku-pods) | ryoku | 0.2.4 | experimental | AirPods in the Ryoku bar: per-pod and case battery, listening mode, adaptive noise level, conversation awareness, one-bud ANC and ear detection. |
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

## How a plugin goes from idea to users

This repository is the only place anyone works in. The per-plugin repositories (the "mirrors")
are copies made by CI: nobody edits them, and `main` here takes pull requests only.

```text
new-plugin.sh  ->  branch + PR  ->  checks + auto version  ->  status set  ->  merge  ->  mirror
 (draft)           (you work)        (CI, nothing to do)       (you decide)    (CI publishes)
```

### 1. Develop
1. `scripts/new-plugin.sh ryoku <id>` creates `linux/ryoku/<id>/`. The plugin starts as a
   `draft`: it is checked like the others but never published.
2. Work on a branch and open a pull request.
3. CI runs by itself on the PR:
   - `validate`: the plugin is well formed (`ryoku plugin validate`, manifest, README, LICENSE,
     shellcheck) and the generated index is up to date;
   - `version`: raises the plugin's version (0.2.0 -> 0.2.1) and refreshes the index. Label the
     PR `bump:minor` or `bump:major` for a bigger step;
   - `mirror`: a dry run that prints what merging would create or change. Nothing is written.

Every change to a plugin raises its version, even a README fix: a version tag never moves.

### 2. Publish
4. When the plugin is ready, set `"status": "experimental"` (or `"stable"`) in its
   `manifest.json`. This is the only publication gesture.
5. Merge the PR. CI then, for that plugin:
   - creates the public repository `<owner>/<id>` the first time (issues off, topics set);
   - copies the plugin folder there as the repository root, so `manifest.json` sits at its root;
   - tags `v<version>`;
   - locks the repository read-only (nobody can push, rewrite or delete tags).

### 3. Distribute
- Users install from the mirror: `ryoku plugin add https://github.com/<owner>/<id> --bar --yes`
  (or from a clone of this repository, see above).
- Every day CI checks the mirrors against this repository. If one was changed by hand, the run
  fails to flag it but overwrites nothing. To reset it, run the `mirror` workflow manually with
  `force`.
- Sharing on Ryostore (`ryoku plugin share`) is separate and stays manual.

### 4. Retire
The manifest `status` drives the whole lifecycle:

| `status` | Published? | Effect on the mirror |
| --- | --- | --- |
| `draft` (default) | no | none, no repository is created |
| `experimental`, `stable` | yes | kept in step with this repository |
| `deprecated` | yes | description starts with `[DEPRECATED]` |
| `archived` | last time | updated one last time, then the repository is archived |

A plugin folder is never deleted (the PR would fail): set it to `archived` instead. To rename a
plugin, create the new folder with `"replaces": "<old-id>"` in its manifest and remove the old
one: the old mirror is archived with a link to the new one. CI never deletes a repository.

## Working here

- [AGENTS.md](AGENTS.md): conventions for contributors and AI agents.
- `scripts/new-plugin.sh ryoku <id>` scaffolds a plugin; `scripts/validate-all.sh` checks them all.
- Licence: MIT, except where a plugin's own `LICENSE` says otherwise. See [CREDITS.md](CREDITS.md).
