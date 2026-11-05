#!/bin/bash
# Validates every plugin: ryoku plugin validate when available, plus structural checks.
# With BASE_REF set (a pull request), also refuses to silently drop a plugin folder and checks
# that the generated index (README table, plugins.json) is up to date.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
fail=0
valid_status="draft experimental stable deprecated archived"

for m in linux/*/*/manifest.json; do
  [ -e "$m" ] || continue
  d=$(dirname "$m")
  id=$(basename "$d")
  jq -e . "$m" >/dev/null 2>&1 || { echo "FAIL $d: invalid manifest.json"; fail=1; continue; }
  [ "$(jq -r '.id // ""' "$m")" = "$id" ] || { echo "FAIL $d: manifest id differs from the folder name (the mirror is named after the folder)"; fail=1; }
  for f in README.md LICENSE; do [ -f "$d/$f" ] || { echo "FAIL $d: missing $f"; fail=1; }; done
  st=$(jq -r '.status // "draft"' "$m")
  case " $valid_status " in *" $st "*) ;; *) echo "FAIL $d: unknown status '$st' ($valid_status)"; fail=1 ;; esac
  rep=$(jq -r '.replaces // empty' "$m")
  if [ -n "$rep" ]; then
    { [[ $rep =~ ^[a-z0-9][a-z0-9-]*$ ]] && [ "$rep" != "$id" ]; } || { echo "FAIL $d: invalid replaces '$rep'"; fail=1; }
  fi
  if [ "$(basename "$(dirname "$d")")" = ryoku ] && command -v ryoku >/dev/null 2>&1; then
    ryoku plugin validate "$d" >/dev/null || { echo "FAIL $d: ryoku plugin validate"; fail=1; }
  fi
  echo "ok   $d ($st)"
done

if [ -n "${BASE_REF:-}" ]; then
  # A plugin folder must not vanish: archive it (status "archived") or, for a rename, declare
  # "replaces" in the new manifest so the old mirror is archived and points to the new one.
  while read -r old; do
    [ -n "$old" ] || continue
    [ -e "$old" ] && continue
    oid=$(basename "$(dirname "$old")")
    if grep -lq "\"replaces\": *\"$oid\"" linux/*/*/manifest.json 2>/dev/null; then
      echo "ok   $oid renamed (replaces)"
    else
      echo "FAIL $oid: folder removed. Keep it with \"status\": \"archived\", or add \"replaces\": \"$oid\" to the manifest of its successor."
      fail=1
    fi
  done < <(git ls-tree -r --name-only "$BASE_REF" -- linux | grep -E '^linux/[^/]+/[^/]+/manifest\.json$' || true)
  scripts/gen-index.sh --check || { echo "FAIL generated index is stale: run scripts/gen-index.sh"; fail=1; }
fi
exit $fail
