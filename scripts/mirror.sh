#!/usr/bin/env bash
# Publishes every plugin folder (linux/<env>/<id>/ holding a manifest.json) to its own
# read-only repository <owner>/<id>. linux-plugins is the only place anyone works in.
#
# The manifest "status" drives the lifecycle (default: draft):
#   draft         not published, no mirror is created or touched
#   experimental  published
#   stable        published
#   deprecated    published, description prefixed "[DEPRECATED]"
#   archived      published one last time, then the mirror is archived (read-only for good)
# A manifest "replaces": "<old-id>" marks a rename: once the new mirror is published, the
# mirror of <old-id> is archived with a pointer to the new one. Nothing is ever deleted.
#
# Per published plugin, in order:
#   1. create the mirror repository if it does not exist (public, named after the folder);
#   2. keep description, homepage and "no issues" in step with the manifest;
#   3. refuse to move a tag (a tag that points elsewhere means the version was not raised);
#   4. push the plugin subtree to main (a diverged mirror is NOT overwritten, unless FORCE=1);
#   5. tag v<manifest version>;
#   6. make sure the read-only rulesets (scripts/mirror-rulesets/*.json) and topics exist;
#   7. archive the mirror when the status is "archived", and retire the replaced one.
#
# Env: MIRROR_TOKEN (needs repo creation, Contents and Administration write), MIRROR_OWNER,
#      SOURCE_REPO (default <owner>/linux-plugins), DRY_RUN=1 (read-only: prints what it would
#      do), FORCE=1 (overwrite a mirror that diverged from the source).
set -euo pipefail

owner=${MIRROR_OWNER:?MIRROR_OWNER is required}
source_repo=${SOURCE_REPO:-$owner/linux-plugins}
dry=${DRY_RUN:-}
force=${FORCE:-}
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

repo_exists() {
  local out
  if out=$(gh api "repos/$1" --jq .full_name 2>&1); then return 0; fi
  if grep -q "HTTP 404" <<<"$out"; then return 1; fi
  echo "::error::cannot read $1: $out"; exit 1
}

create_repo() { # <id> <description> <homepage>
  local endpoint="user/repos"
  [ "$(gh api "users/$owner" --jq .type)" = "Organization" ] && endpoint="orgs/$owner/repos"
  mutate gh api -X POST "$endpoint" -f name="$1" -f description="$2" -f homepage="$3" \
    -F private=false -F has_issues=false -F has_wiki=false -F has_projects=false
}

ensure_rulesets() { # <repo>
  local existing f name
  existing=$(gh api "repos/$1/rulesets" --jq '.[].name' 2>/dev/null || true)
  for f in scripts/mirror-rulesets/*.json; do
    name=$(jq -r .name "$f")
    if grep -qxF "$name" <<<"$existing"; then continue; fi
    echo "$1: adding ruleset \"$name\""
    mutate gh api -X POST "repos/$1/rulesets" --input "$f"
  done
}

ensure_topics() { # <repo> <environment>
  local want have
  want=$(printf '%s\n' linux-plugin "$2" | sort | paste -sd, -)
  have=$(gh api "repos/$1/topics" --jq '.names | sort | join(",")' 2>/dev/null || true)
  [ "$have" = "$want" ] && return 0
  echo "$1: topics -> $want"
  mutate gh api -X PUT "repos/$1/topics" -f 'names[]=linux-plugin' -f "names[]=$2"
}

# The mirror of a renamed plugin is archived and points to its successor.
retire_replaced() { # <old-id> <new-id>
  local old="$owner/$1"
  repo_exists "$old" || return 0
  [ "$(gh api "repos/$old" --jq .archived)" = "true" ] && return 0
  echo "$old: replaced by $2, archiving it"
  mutate gh api -X PATCH "repos/$old" -f description="Renamed to $2: https://github.com/$owner/$2" \
    -f homepage="https://github.com/$owner/$2" -F archived=true
}

rc=0
for manifest in linux/*/*/manifest.json; do
  [ -e "$manifest" ] || continue
  path=$(dirname "$manifest")
  id=$(basename "$path")
  env_name=$(basename "$(dirname "$path")")
  repo="$owner/$id"
  url="https://${auth}github.com/${repo}.git"

  if [ "$(jq -r .id "$manifest")" != "$id" ]; then
    echo "::error::$path: manifest id '$(jq -r .id "$manifest")' differs from the folder name '$id' (the mirror is named after the folder)"
    rc=1; continue
  fi

  plugin_status=$(jq -r '.status // "draft"' "$manifest")
  case $plugin_status in
    draft)
      echo "$id: draft, not published"
      if repo_exists "$repo"; then echo "::warning::$repo exists but $id is draft: left untouched"; fi
      continue ;;
    experimental|stable|deprecated|archived) ;;
    *) echo "::error::$path: unknown status '$plugin_status' (draft|experimental|stable|deprecated|archived)"
       rc=1; continue ;;
  esac

  prefix=""
  case $plugin_status in
    deprecated) prefix="[DEPRECATED] " ;;
    archived)   prefix="[ARCHIVED] " ;;
  esac
  desc="${prefix}$(jq -r '.description // .name' "$manifest") (read-only mirror of $source_repo/$path)"
  desc=${desc:0:340}
  home="https://github.com/$source_repo/tree/main/$path"
  split=$(git subtree split --prefix="$path")
  tag="v$(git show "$split:manifest.json" | jq -r .version)"

  if repo_exists "$repo"; then
    info=$(gh api "repos/$repo" --jq '[.archived, (.description // ""), (.homepage // ""), .has_issues] | @json')
    if [ "$(jq -r '.[0]' <<<"$info")" = "true" ]; then
      if [ "$plugin_status" = archived ]; then echo "$repo is archived, nothing to do"; continue; fi
      echo "$repo: status is $plugin_status, unarchiving"
      mutate gh api -X PATCH "repos/$repo" -F archived=false
    fi
    if [ "$(jq -r '.[1]' <<<"$info")" != "$desc" ] || [ "$(jq -r '.[2]' <<<"$info")" != "$home" ] \
       || [ "$(jq -r '.[3]' <<<"$info")" != "false" ]; then
      mutate gh api -X PATCH "repos/$repo" -f description="$desc" -f homepage="$home" -F has_issues=false
    fi
  else
    echo "$repo does not exist: creating it"
    create_repo "$id" "$desc" "$home"
    if [ -n "$dry" ]; then
      echo "[dry-run] would push $path ($split) to $repo and tag $tag"
      continue
    fi
  fi

  tag_sha=$(git ls-remote "$url" "refs/tags/$tag" | cut -f1)
  if [ -n "$tag_sha" ] && [ "$tag_sha" != "$split" ]; then
    echo "::error::$repo: $tag already points to another commit; raise the version in $path/manifest.json (tags never move). Mirror left untouched."
    rc=1; continue
  fi

  remote=$(git ls-remote "$url" refs/heads/main | cut -f1)
  if [ "$remote" = "$split" ]; then
    echo "$repo is up to date"
  else
    if [ -n "$remote" ]; then
      git fetch --quiet --no-tags "$url" main
      if ! git merge-base --is-ancestor "$remote" "$split"; then
        if [ -n "$force" ]; then
          echo "::warning::$repo diverged from $source_repo (commit $remote is not in the source history); overwriting it (FORCE)"
        else
          echo "::error::$repo diverged from $source_repo (commit $remote is not in the source history). Nothing was overwritten; rerun the mirror workflow manually with force to reset it."
          rc=1; continue
        fi
      fi
    fi
    mutate git push --force "$url" "$split:refs/heads/main"
  fi

  if [ -z "$tag_sha" ]; then
    mutate git tag -f "$tag" "$split"
    mutate git push "$url" "refs/tags/$tag"
    echo "$repo: tagged $tag"
  fi

  ensure_rulesets "$repo"
  ensure_topics "$repo" "$env_name"

  replaced=$(jq -r '.replaces // empty' "$manifest")
  [ -z "$replaced" ] || retire_replaced "$replaced" "$id"

  if [ "$plugin_status" = archived ]; then
    echo "$repo: archiving"
    mutate gh api -X PATCH "repos/$repo" -F archived=true
  fi
done
exit $rc
