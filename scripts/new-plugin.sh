#!/bin/bash
# Usage: scripts/new-plugin.sh ryoku <id> [name]   (Omarchy: create the folder by hand)
set -euo pipefail
env=${1:-}; id=${2:-}; name=${3:-$id}
[ "$env" = ryoku ] && [ -n "$id" ] || { echo "usage: $0 ryoku <id> [name]" >&2; exit 2; }
root=$(cd "$(dirname "$0")/.." && pwd)
ryoku plugin new "$id" --bar --name "$name" --to "$root/linux/ryoku"
manifest="$root/linux/ryoku/$id/manifest.json"
tmp=$(mktemp)
jq '. + {status: "draft"}' "$manifest" > "$tmp" && mv "$tmp" "$manifest"
"$root/scripts/gen-index.sh"
echo "created linux/ryoku/$id (status: draft)"
echo "next: add it to CREDITS.md if it derives from other work, then open a PR."
echo "a draft is never published. When ready, set \"status\" to experimental or stable in its manifest:"
echo "merging that creates https://github.com/<owner>/$id (read-only mirror) and tags v<version> by itself."
