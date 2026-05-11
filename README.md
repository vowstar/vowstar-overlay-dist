# vowstar-overlay-dist

Pre-built dependency tarballs for ebuilds in
[vowstar-overlay](https://github.com/vowstar/vowstar-overlay).

This repository exists so that ebuilds with large external dependency sets
(Go modules, Rust crates, Node packages) can fetch a single pre-bundled
tarball from a GitHub release instead of listing thousands of entries
inline (e.g. the deprecated `EGO_SUM`, or oversized `CRATES=`).

## How it works

1. Each package has a small declarative config under `packages/<category>/<name>.yml`.
2. A GitHub Actions dispatcher (`.github/workflows/dispatch.yml`) runs daily
   and on demand; it scans `packages/`, detects the latest upstream version,
   and routes the build to a per-ecosystem reusable workflow.
3. The build script (`scripts/build-<kind>-deps.sh`) fetches upstream source,
   populates the dependency cache, packs it as `${name}-${version}-deps.tar.xz`,
   and uploads it to a GitHub release tagged `${name}-${version}`.
4. ebuilds in vowstar-overlay reference the asset directly:

   ```
   SRC_URI="
       <upstream source>
       https://github.com/vowstar/vowstar-overlay-dist/releases/download/${PN}-${PV}/${P}-deps.tar.xz
   "
   ```

The scripts are plain shell and runnable locally for debugging — GitHub
Actions only orchestrates them.

## Adding a package

Drop a YAML file under `packages/<category>/<name>.yml`. Minimal Go example:

```yaml
kind: go
category: app-containers
name: amd-container-toolkit
upstream:
  source: github
  repo: ROCm/container-toolkit
  tag_prefix: v
src:
  url: https://github.com/ROCm/container-toolkit/archive/v{version}.tar.gz
  extract: container-toolkit-{version}
```

Push to `main`; the dispatcher picks it up on the next cron tick, or trigger
manually:

```
gh workflow run dispatch.yml -R vowstar/vowstar-overlay-dist \
    -f package=amd-container-toolkit
```

## Supported ecosystems

| kind   | status  | output asset suffix |
| ------ | ------- | ------------------- |
| `go`   | ready   | `-deps.tar.xz`      |
| `rust` | planned | `-deps.tar.xz`      |
| `node` | planned | `-deps.tar.xz`      |

## Layout

```
packages/<category>/<name>.yml      package configs
scripts/build-<kind>-deps.sh        per-ecosystem build script
scripts/lib/                        shared helpers (plan, detect, upload)
.github/workflows/dispatch.yml      cron + manual entry point
.github/workflows/build-<kind>.yml  reusable workflow per ecosystem
```
