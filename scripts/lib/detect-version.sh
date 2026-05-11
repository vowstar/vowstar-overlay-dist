#!/usr/bin/env bash
# Detect the latest upstream version for a package config.
#
# Usage: detect-version.sh <config.yml>
# Prints the bare version (no tag prefix) on stdout.

set -euo pipefail

config="$1"
source=$(yq -r '.upstream.source' "$config")

case "$source" in
    github)
        repo=$(yq -r '.upstream.repo' "$config")
        prefix=$(yq -r '.upstream.tag_prefix // ""' "$config")
        api="https://api.github.com/repos/${repo}/releases/latest"
        auth=()
        [ -n "${GH_TOKEN:-}" ] && auth=(-H "Authorization: Bearer ${GH_TOKEN}")
        tag=$(curl -sfL "${auth[@]}" "$api" | jq -r .tag_name)
        if [ -z "$tag" ] || [ "$tag" = "null" ]; then
            echo "no release found at $api" >&2
            exit 1
        fi
        echo "${tag#$prefix}"
        ;;
    *)
        echo "unsupported upstream source: $source" >&2
        exit 1
        ;;
esac
