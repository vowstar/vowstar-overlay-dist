#!/usr/bin/env bash
# Idempotently publish a tarball as a GitHub release asset.
#
# Usage: release-upload.sh <tag> <file>
# Skips if the asset already exists; otherwise creates the release
# (if needed) and uploads the file.

set -euo pipefail

tag="$1"
file="$2"
asset="$(basename "$file")"

if gh release view "$tag" >/dev/null 2>&1; then
    if gh release view "$tag" --json assets -q '.assets[].name' \
            | grep -qx "$asset"; then
        echo "release ${tag} already has ${asset}; nothing to do"
        exit 0
    fi
    gh release upload "$tag" "$file"
else
    gh release create "$tag" "$file" \
        --title "$tag" \
        --notes "Automated dependency tarball for ${tag}." \
        --latest=false
fi
