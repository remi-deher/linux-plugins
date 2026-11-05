#!/usr/bin/env bash
# Generates the plugin index from the manifests:
#   - the table of README.md between <!-- plugins:start --> and <!-- plugins:end -->;
#   - plugins.json (one entry per plugin).
# Usage: scripts/gen-index.sh [--check]   (--check changes nothing and fails when stale)
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
owner=${MIRROR_OWNER:-remi-deher}

entries='[]'
for m in linux/*/*/manifest.json; do
  [ -e "$m" ] || continue
  d=$(dirname "$m")
  entries=$(jq --argjson e "$entries" --arg path "$d" --arg env "$(basename "$(dirname "$d")")" --arg owner "$owner" \
    '$e + [{id, name, environment: $env, version, status: (.status // "draft"),
       description: (.description // .name), path: $path,
       mirror: (if (.status // "draft") == "draft" then null else "https://github.com/\($owner)/\(.id)" end)}]' \
    "$m")
done
json=$(jq 'sort_by(.environment, .id)' <<<"$entries")

table=$(jq -r '"| Plugin | Environment | Version | Status | What it does |", "| --- | --- | --- | --- | --- |",
  (.[] | "| [\(.id)](\(.path)) | \(.environment) | \(.version) | \(.status) | \(.description | gsub("\\|"; "/")) |")' <<<"$json")

new_readme=$(awk -v table="$table" '
  /<!-- plugins:start -->/ { print; print table; skip=1; next }
  /<!-- plugins:end -->/   { skip=0 }
  !skip { print }' README.md)

if [ "${1:-}" = "--check" ]; then
  [ "$new_readme" = "$(cat README.md)" ] && [ "$json" = "$(cat plugins.json 2>/dev/null)" ]
else
  printf '%s\n' "$new_readme" > README.md
  printf '%s\n' "$json" > plugins.json
fi
