#!/bin/bash
# Usage: scripts/new-plugin.sh ryoku <id> [name]   (Omarchy: create the folder by hand)
set -euo pipefail
env=${1:-}; id=${2:-}; name=${3:-$id}
[ "$env" = ryoku ] && [ -n "$id" ] || { echo "usage: $0 ryoku <id> [name]" >&2; exit 2; }
root=$(cd "$(dirname "$0")/.." && pwd)
ryoku plugin new "$id" --bar --name "$name" --to "$root/linux/ryoku"
echo "created linux/ryoku/$id; add it to CREDITS.md if it derives from other work"
