#!/usr/bin/env bash
# Build a Go module-cache tarball for one package.
#
# Usage: build-go-deps.sh <config.yml> <version> [output_dir]
# Writes ${name}-${version}-deps.tar.xz to output_dir (default: $PWD)
# and prints its absolute path on stdout.
#
# The tarball expands to a single top-level directory named "go-mod",
# which the consuming ebuild points GOMODCACHE at.

set -euo pipefail

config="$1"
version="$2"
out_dir="${3:-$PWD}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

name=$(yq -r '.name' "$config")
src_url=$(yq -r '.src.url' "$config" | sed "s/{version}/${version}/g")
extract=$(yq -r '.src.extract' "$config" | sed "s/{version}/${version}/g")

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

(
    cd "$work"
    echo "fetching ${src_url}" >&2
    curl -sfL "$src_url" | tar xz
    cd "$extract"
    GOMODCACHE="$work/go-mod" GOFLAGS="-mod=mod" \
        go mod download -modcacherw -x
)

out="${name}-${version}-deps.tar.xz"
XZ_OPT="-9 -T0" tar --create --auto-compress \
    --file "$out_dir/$out" \
    -C "$work" go-mod

echo "$out_dir/$out"
