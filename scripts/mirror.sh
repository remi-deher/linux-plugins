#!/usr/bin/env bash
# Publishes every plugin folder (linux/<env>/<id>/ holding a manifest.json) to its own
# read-only repository <owner>/<id>. linux-plugins is the only place anyone works in.
#
# Per plugin, in order:
#   1. create the mirror repository if it does not exist (public, named after the folder);
#   2. keep its description in step with manifest.json;
#   3. push the plugin subtree to main (identical mirror: skipped; diverged: overwritten, run fails);
#   4. tag v<manifest version> when that tag does not exist yet;
#   5. make sure the read-only rulesets (scripts/mirror-rulesets/*.json) exist on the mirror.
#
# Env: MIRROR_TOKEN (needs repo creation, Contents and Administration write), MIRROR_OWNER,
#      SOURCE_REPO (default <owner>/linux-plugins), DRY_RUN=1 (read-only: prints what it would do).
set -euo pipefail

owner=${MIRROR_OWNER:?MIRROR_OWNER is required}
source_repo=${SOURCE_REPO:-$owner/linux-plugins}
dry=${DRY_RUN:-}
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"

if [ -n "${MIRROR_TOKEN:-}" ]; then
  export GH_TOKEN=$MIRROR_TOKEN
  auth="x-access-token:${MIRROR_TOKEN}@"
elif [ -z "$dry" ]; then
  echo "::error::MIRROR_TOKEN is not set, mirrors cannot be updated"; exit 1
else
  auth=""
fi


# Mutations go through this, so a dry run only reads.
mutate() { if [ -n "$dry" ]; then echo "[dry-run] $*"; else "$@" >/dev/null; fi; }

# Administration calls (create, description, rulesets) need a token with Administration write.
# When one fails the code is still synchronised; the run is marked failed so it gets fixed.
admin_failed=0
admin() {
  if ! "$@"; then
    echo "::error::$* failed: MIRROR_TOKEN probably lacks Administration (repository) write permission"
    admin_failed=1
    return 1
  fi
}

repo_exists() {
  local out
  if out=$(gh api "repos/$1" --jq .full_name 2>&1); then return 0; fi
  if grep -q "HTTP 404" <<<"$out"; then return 1; fi
  echo "::error::cannot read $1: $out"; exit 1
}

create_repo() { # <id> <description>
  local endpoint="user/repos"
  [ "$(gh api "users/$owner" --jq .type)" = "Organization" ] && endpoint="orgs/$owner/repos"
  mutate gh api -X POST "$endpoint" -f name="$1" -f description="$2" \
    -F private=false -F has_wiki=false -F has_projects=false
}

ensure_rulesets() { # <repo>
  local existing f name
  existing=$(gh api "repos/$1/rulesets" --jq '.[].name')
  for f in scripts/mirror-rulesets/*.json; do
    name=$(jq -r .name "$f")
    if grep -qxF "$name" <<<"$existing"; then continue; fi
    echo "$1: adding ruleset \"$name\""
    mutate gh api -X POST "repos/$1/rulesets" --input "$f"
  done
}

status=0
for manifest in linux/*/*/manifest.json; do
  [ -e "$manifest" ] || continue
  path=$(dirname "$manifest")
  id=$(basename "$path")
  repo="$owner/$id"
  url="https://${auth}github.com/${repo}.git"

  if [ "$(jq -r .id "$manifest")" != "$id" ]; then
    echo "::error::$path: manifest id '$(jq -r .id "$manifest")' differs from the folder name '$id' (the mirror is named after the folder)"
    status=1; continue
  fi

  desc="$(jq -r '.description // .name' "$manifest") (read-only mirror of $source_repo/$path)"
  desc=${desc:0:340}
  split=$(git subtree split --prefix="$path")

  if ! repo_exists "$repo"; then
    echo "$repo does not exist: creating it"
    if ! admin create_repo "$id" "$desc"; then status=1; continue; fi
    if [ -n "$dry" ]; then
      echo "[dry-run] would push $path ($split) to $repo and tag v$(git show "$split:manifest.json" | jq -r .version)"
      continue
    fi
  fi

  remote=$(git ls-remote "$url" refs/heads/main | cut -f1)
  if [ "$remote" = "$split" ]; then
    echo "$repo is up to date"
  else
    if [ -n "$remote" ]; then
      git fetch --quiet --no-tags "$url" main
      if ! git merge-base --is-ancestor "$remote" "$split"; then
        echo "::error::$repo diverged from $source_repo (commit $remote is not in the source history); overwriting it"
        status=1
      fi
    fi
    mutate git push --force "$url" "$split:refs/heads/main"
  fi

  tag="v$(git show "$split:manifest.json" | jq -r .version)"
  tag_sha=$(git ls-remote "$url" "refs/tags/$tag" | cut -f1)
  if [ -z "$tag_sha" ]; then
    mutate git tag "$tag" "$split"
    mutate git push "$url" "refs/tags/$tag"
    echo "$repo: tagged $tag"
  elif [ "$tag_sha" != "$split" ]; then
    echo "::warning::$repo: $tag already points to another commit; bump the version in $path/manifest.json to publish a new tag"
  fi

  # Administration steps come last, so a token without that permission still syncs the code.
  current=$(gh api "repos/$repo" --jq '.description // ""' 2>/dev/null || true)
  [ "$current" = "$desc" ] || admin mutate gh api -X PATCH "repos/$repo" -f description="$desc" || true
  admin ensure_rulesets "$repo" || true
done
[ "$admin_failed" = 0 ] || status=1
exit $status
