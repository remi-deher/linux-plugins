# Agent guide for linux-plugins

This repository is the single source of truth. Each plugin folder is copied by CI to its own
read-only repository (the mirror). See the README for the full path from idea to users.

## Layout and content
- One plugin per folder: `linux/<environment>/<id>/`, with `manifest.json` at that folder's root, plus `README.md` and `LICENSE`. The manifest `id` must equal the folder name (the mirror is named after the folder).
- Ryoku plugins follow Ryoku's rules R1-R11 (`ryoku plugin validate <dir>` must report 0 blocking). Read the plugin's own `AGENTS.md` if it has one (`ryoku plugin new` generates it).
- Never ship compiled binaries or third-party daemons. Reference upstream in the plugin README and in `CREDITS.md` instead.
- A plugin that derives from other work keeps that author's copyright in its `LICENSE` and has a row in `CREDITS.md`.
- Create plugins with `scripts/new-plugin.sh ryoku <id>`; check them with `scripts/validate-all.sh`.

## Lifecycle (manifest `status`, missing means `draft`)
- `draft`: never published, no mirror is created. New plugins start here.
- `experimental`, `stable`: mirrored.
- `deprecated`: mirrored, description prefixed `[DEPRECATED]`.
- `archived`: mirrored one last time, then the mirror is archived.
- Never delete a plugin folder (`validate` fails). Keep it with `status: archived`. For a rename, add `"replaces": "<old-id>"` to the new manifest: the old mirror is archived with a pointer to the new one.
- **Do not publish unless the owner asks.** Moving a plugin out of `draft` and merging publishes it (public mirror). `ryoku plugin share` (Ryostore) is separate and stays manual.

## Automation (do not redo it by hand)
- `validate.yml`: runs `scripts/validate-all.sh` (plugins, removed folders, generated index) and shellcheck, which must pass.
- `version.yml`: on each PR, raises the manifest version of every plugin folder the PR changes (patch by default; label the PR `bump:minor` or `bump:major` for more) and refreshes the index. It pushes with `MIRROR_TOKEN`, so the other workflows run on its commit normally. Do not edit `version` by hand unless you want a higher one.
- `mirror.yml` (`scripts/mirror.sh`): on a PR or any branch other than `main` it is a dry run. On `main` and daily it creates the mirror on first publication, keeps description, homepage, topics and "issues off" in step with the manifest, pushes the plugin folder as the mirror's root, tags `v<version>` and adds the read-only rulesets.
- A tag never moves: a plugin change without a new version fails the mirror run. A mirror that diverged is never overwritten by itself; rerun the `mirror` workflow manually with `force` to reset it.
- The README table and `plugins.json` are generated from the manifests (`scripts/gen-index.sh`): do not edit the table by hand.
- There is no `mirrors.json` and no GitHub Release. Do not create mirror repositories by hand.

## Working rules
- `main` accepts pull requests only, and mirror repositories are read-only: never push to either directly.
- Commit messages in French or English, no co-author trailers.
