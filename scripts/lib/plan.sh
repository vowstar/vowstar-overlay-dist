#!/usr/bin/env bash
# Scan packages/ and emit one JSON array per kind to GITHUB_OUTPUT.
#
# Usage: plan.sh [filter]
#   filter — optional substring; only configs whose path under packages/
#            contains the substring are included.
#
# Outputs:
#   go=[...]   rust=[...]   node=[...]
#
# Each array element is the path to a config file relative to repo root,
# e.g. "packages/app-containers/amd-container-toolkit.yml".

set -euo pipefail

filter="${1:-}"
root="$(cd "$(dirname "$0")/../.." && pwd)"

declare -A items=([go]="" [rust]="" [node]="")

while IFS= read -r -d '' f; do
    rel="${f#$root/}"
    if [ -n "$filter" ] && [[ "$rel" != *"$filter"* ]]; then
        continue
    fi
    kind=$(yq -r '.kind' "$f")
    case "$kind" in
        go|rust|node)
            items[$kind]+="\"${rel}\","
            ;;
        *)
            echo "::warning file=${rel}::unknown kind: ${kind}" >&2
            ;;
    esac
done < <(find "$root/packages" -name '*.yml' -print0 | sort -z)

out="${GITHUB_OUTPUT:-/dev/stdout}"
for kind in go rust node; do
    list="${items[$kind]}"
    if [ -n "$list" ]; then
        echo "${kind}=[${list%,}]" >> "$out"
    else
        echo "${kind}=[]" >> "$out"
    fi
done
