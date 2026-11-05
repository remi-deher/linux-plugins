# Agent guide for linux-plugins

- One plugin per folder: `linux/<environment>/<id>/`, with `manifest.json` at that folder's root, plus `README.md` and `LICENSE`.
- Ryoku plugins follow Ryoku's rules R1–R11 (`ryoku plugin validate <dir>` must report 0 blocking). Read the plugin's own `AGENTS.md` if it has one (`ryoku plugin new` generates it).
- Never ship compiled binaries or third-party daemons. Reference upstream in the plugin README and in `CREDITS.md` instead.
- A plugin that derives from other work keeps that author's copyright in its `LICENSE` and has a row in `CREDITS.md`.
- Lifecycle is the manifest `status` (missing means `draft`): `draft` is never published; `experimental` and `stable` are mirrored; `deprecated` is mirrored with a `[DEPRECATED]` description; `archived` is mirrored one last time, then the mirror is archived. Set `experimental` or `stable` only when the owner asks to publish.
- Never delete a plugin folder. Keep it with `status: archived`, or for a rename add `"replaces": "<old-id>"` to the new manifest: the old mirror is then archived with a pointer to the new one. `validate` fails otherwise.
- Publication is automatic. A plugin folder that is not `draft` is mirrored to `<owner>/<folder name>` (so the manifest `id` must equal the folder name). `mirror.yml` creates that repository on the first merge to `main`, keeps description, homepage, topics and "issues off" in step with the manifest, pushes the subtree, tags `v<version>` and adds the read-only rulesets (`scripts/mirror.sh`). A pull request runs it as a dry run and prints what merging would do. There is no `mirrors.json` and no GitHub Release: do not create mirror repositories by hand. A mirror that diverged is never overwritten by itself; rerun the `mirror` workflow manually with `force` to reset it.
- Do not publish unless the owner asks: merging a PR that moves a plugin out of `draft` publishes it (public mirror), and `ryoku plugin share` (Ryostore) is separate and stays manual.
- Commit messages in French or English, no co-author trailers.
- Versioning is automatic: on each PR, `version.yml` raises the manifest version of every plugin folder the PR changes (patch by default; label the PR `bump:minor` or `bump:major` for more). Do not edit `version` by hand unless you want a higher one. `mirror.yml` then tags `v<version>` on the plugin's mirror; a tag never moves, so a change without a new version fails the mirror run.
- The README table and `plugins.json` are generated from the manifests (`scripts/gen-index.sh`, refreshed by `version.yml`): do not edit the table by hand.
- `main` accepts pull requests only, and mirror repositories are read-only: never push to either directly.
