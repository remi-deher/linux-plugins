# Agent guide for linux-plugins

- One plugin per folder: `linux/<environment>/<id>/`, with `manifest.json` at that folder's root, plus `README.md` and `LICENSE`.
- Ryoku plugins follow Ryoku's rules R1–R11 (`ryoku plugin validate <dir>` must report 0 blocking). Read the plugin's own `AGENTS.md` if it has one (`ryoku plugin new` generates it).
- Never ship compiled binaries or third-party daemons. Reference upstream in the plugin README and in `CREDITS.md` instead.
- A plugin that derives from other work keeps that author's copyright in its `LICENSE` and has a row in `CREDITS.md`.
- Publication is automatic. A plugin folder is mirrored to `<owner>/<folder name>` (so the manifest `id` must equal the folder name). `mirror.yml` creates that repository on the first merge to `main`, keeps its description in step with the manifest, pushes the subtree, tags `v<version>` and adds the read-only rulesets (`scripts/mirror.sh`). A pull request runs it as a dry run and prints what merging would do. There is no `mirrors.json`: do not create mirror repositories by hand.
- Do not publish unless the owner asks: merging a PR that adds a plugin folder publishes it (public mirror), and `ryoku plugin share` (Ryostore) is separate and stays manual.
- Commit messages in French or English, no co-author trailers.
- Versioning is automatic: on each PR, `version.yml` raises the manifest version of every plugin folder the PR changes (patch by default; label the PR `bump:minor` or `bump:major` for more). Do not edit `version` by hand unless you want a higher one. `mirror.yml` then tags `v<version>` on the plugin's mirror.
- `main` accepts pull requests only, and mirror repositories are read-only: never push to either directly.
