#!/bin/bash
# Validates every plugin: ryoku plugin validate when available, plus structural checks.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
fail=0
for m in "$root"/linux/*/*/manifest.json; do
  [ -e "$m" ] || continue
  d=$(dirname "$m")
  rel=${d#"$root"/}
  python3 -c 'import json,sys; json.load(open(sys.argv[1]))' "$m" || { echo "FAIL $rel: invalid manifest.json"; fail=1; continue; }
  for f in README.md LICENSE; do [ -f "$d/$f" ] || { echo "FAIL $rel: missing $f"; fail=1; }; done
  if [ "$(basename "$(dirname "$d")")" = ryoku ] && command -v ryoku >/dev/null 2>&1; then
    ryoku plugin validate "$d" >/dev/null || { echo "FAIL $rel: ryoku plugin validate"; fail=1; }
  fi
  echo "ok   $rel"
done
exit $fail
