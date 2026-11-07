# gstreamer-macos-binaries

Unmodified upstream GStreamer macOS installers, re-published as GitHub release
assets for CI pinning and SHA-256 verification.

## Purpose

Upstream installers live at:

    https://gstreamer.freedesktop.org/data/pkg/osx/<version>/<asset>

This mirror gives CI a stable, checksum-verified download URL on GitHub.
**No upstream bytes are modified** - the `.pkg` files are byte-for-byte
identical to the upstream files. Each asset ships with a `.sha256` sidecar so
consumers can verify integrity locally.

## Assets

For a release tagged `<v>` (e.g. `1.28.1`):

| Asset | Contents |
|---|---|
| `gstreamer-1.0-<v>-universal.pkg` | Runtime: `GStreamer.framework` binaries. |
| `gstreamer-1.0-<v>-universal.pkg.sha256` | SHA-256 sidecar (`shasum -a 256` output format). |
| `gstreamer-1.0-devel-<v>-universal.pkg` | Development: `Headers`, `Commands`, `pkg-config` files, etc. |
| `gstreamer-1.0-devel-<v>-universal.pkg.sha256` | SHA-256 sidecar. |
| `gstreamer-macos-<v>.manifest.txt` | Per-asset name, size and SHA-256. |
| `gstreamer-macos-<v>.provenance.json` | Upstream source URLs, SHA-256s, ISO-8601 publish timestamp, hostname, script version. |

Upstream names the development package `devel` (not `development`); the mirror
keeps upstream naming exactly. The upstream debug package
(`gstreamer-1.0-debug-<v>-universal.pkg`) is intentionally not mirrored.

## How CI consumes it

    V=1.28.1
    BASE="https://github.com/bastianX6/gstreamer-macos-binaries/releases/download/${V}"
    curl -fLO "${BASE}/gstreamer-1.0-${V}-universal.pkg"
    curl -fLO "${BASE}/gstreamer-1.0-${V}-universal.pkg.sha256"
    shasum -a 256 -c "gstreamer-1.0-${V}-universal.pkg.sha256"

## Publishing a new version

    scripts/publish-release.sh --version 1.28.1          # fails if release exists
    scripts/publish-release.sh --version 1.28.1 --force  # delete and republish
