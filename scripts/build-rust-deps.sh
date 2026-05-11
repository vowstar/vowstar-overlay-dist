#!/usr/bin/env bash
# Build a Gentoo-style crate tarball for one Rust package.
#
# Usage: build-rust-deps.sh <config.yml> <version> [output_dir]
# Writes ${name}-${version}-crates.tar.xz to output_dir (default: $PWD)
# and prints its absolute path on stdout.
#
# The tarball is produced by pycargoebuild (the same tool used by Gentoo
# proper for `--crate-tarball`), so it is layout-compatible with
# cargo.eclass's `cargo_src_unpack` when CRATES="" is set in the ebuild.
#
# Required tooling (must already be installed):
#   - python3 with pycargoebuild
#   - cargo / rustc (for `cargo update` if requested)
#   - curl, tar, yq

set -euo pipefail

config="$1"
version="$2"
out_dir="${3:-$PWD}"
mkdir -p "$out_dir"
out_dir="$(cd "$out_dir" && pwd)"

name=$(yq -r '.name' "$config")
src_url=$(yq -r '.src.url' "$config" | sed "s/{version}/${version}/g")
extract=$(yq -r '.src.extract' "$config" | sed "s/{version}/${version}/g")
directories=$(yq -r '.rust.directories // "."' "$config")
run_cargo_update=$(yq -r '.rust.run_cargo_update // false' "$config")

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

(
    cd "$work"
    echo "fetching ${src_url}" >&2
    curl -sfL "$src_url" | tar xz
    cd "$extract"

    echo "fetching Gentoo license-mapping.conf" >&2
    curl -sfLO https://raw.githubusercontent.com/gentoo/gentoo/refs/heads/master/metadata/license-mapping.conf

    if [ "$run_cargo_update" = "true" ]; then
        echo "running cargo update" >&2
        cargo update
    fi

    out="${name}-${version}-crates.tar.xz"
    echo "running pycargoebuild --crate-tarball" >&2
    pycargoebuild \
        --crate-tarball \
        --crate-tarball-path "${work}/${out}" \
        --distdir "${work}/dist" \
        --license-mapping license-mapping.conf \
        ${directories}
)

out="${name}-${version}-crates.tar.xz"
mv "${work}/${out}" "${out_dir}/${out}"
echo "${out_dir}/${out}"
