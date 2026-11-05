#!/usr/bin/env bash
# Raises the manifest version of every plugin folder a PR changed.
# Usage: scripts/bump-versions.sh <base-ref> <patch|minor|major>
#
# The target is always derived from the version on the base branch, so running it twice
# (or after a label change) gives the same result. A version the author already set higher
# than the target is kept. A brand-new plugin keeps the version it was created with.
set -euo pipefail

base=${1:?usage: bump-versions.sh <base-ref> <patch|minor|major>}
level=${2:-patch}
bumped=0

for manifest in linux/*/*/manifest.json; do
  dir=$(dirname "$manifest")
  git diff --quiet "$base"...HEAD -- "$dir" && continue

  old=$(git show "$base:$manifest" 2>/dev/null | jq -r '.version // empty' || true)
  if [ -z "$old" ]; then echo "$dir: new plugin, version left as is"; continue; fi
  if ! [[ $old =~ ^([0-9]+)\.([0-9]+)\.([0-9]+)$ ]]; then
    echo "::warning::$dir: version '$old' is not x.y.z, not bumped"; continue
  fi
  major=${BASH_REMATCH[1]} minor=${BASH_REMATCH[2]} patch=${BASH_REMATCH[3]}
  case $level in
    major) target="$((major + 1)).0.0" ;;
    minor) target="$major.$((minor + 1)).0" ;;
    *)     target="$major.$minor.$((patch + 1))" ;;
  esac

  cur=$(jq -r '.version' "$manifest")
  if [ "$cur" = "$target" ]; then echo "$dir: already $target"; continue; fi
  if [ "$(printf '%s\n%s\n' "$cur" "$target" | sort -V | tail -1)" = "$cur" ]; then
    echo "$dir: $cur is higher than $target, kept"; continue
  fi

  # Targeted edit: the first "version" key is the manifest's own; formatting stays untouched.
  sed -i -E '0,/"version": *"[^"]*"/s//"version": "'"$target"'"/' "$manifest"
  echo "$dir: $old -> $target ($level)"
  bumped=$((bumped + 1))
done

echo "bumped=$bumped"
