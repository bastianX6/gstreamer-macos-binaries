#!/usr/bin/env bash
# publish-release.sh - mirror upstream GStreamer macOS installers to a GitHub release.
# Usage: publish-release.sh --version <v> [--force]
set -euo pipefail

SCRIPT_VERSION="1.0.0"
REPO="bastianX6/gstreamer-macos-binaries"
PREFIX="gstreamer"

VERSION=""
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --force)   FORCE=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done
[ -n "$VERSION" ] || { echo "usage: $0 --version <v> [--force]" >&2; exit 2; }

UPSTREAM="https://gstreamer.freedesktop.org/data/pkg/osx/${VERSION}"
ASSETS=(
  "gstreamer-1.0-${VERSION}-universal.pkg"
  "gstreamer-1.0-devel-${VERSION}-universal.pkg"
)

if gh release view "$VERSION" --repo "$REPO" >/dev/null 2>&1; then
  if [ "$FORCE" -eq 1 ]; then
    echo "release $VERSION exists; deleting (--force)"
    gh release delete "$VERSION" --repo "$REPO" --yes
  else
    echo "error: release $VERSION already exists (use --force to overwrite)" >&2
    exit 1
  fi
fi

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT
cd "$WORKDIR"

for asset in "${ASSETS[@]}"; do
  echo "downloading $asset"
  curl --fail --location --retry 3 --max-time 3600 -o "$asset" "${UPSTREAM}/${asset}"
  shasum -a 256 "$asset" > "${asset}.sha256"
done

MANIFEST="${PREFIX}-macos-${VERSION}.manifest.txt"
: > "$MANIFEST"
for asset in "${ASSETS[@]}"; do
  size=$(stat -f %z "$asset")
  hash=$(shasum -a 256 "$asset" | awk '{print $1}')
  printf '%s\t%s\t%s\n' "$asset" "$size" "$hash" >> "$MANIFEST"
done

runtime_hash=$(shasum -a 256 "${ASSETS[0]}" | awk '{print $1}')
devel_hash=$(shasum -a 256 "${ASSETS[1]}" | awk '{print $1}')
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
host=$(hostname)

cat > "${PREFIX}-macos-${VERSION}.provenance.json" <<JSON
{
  "prefix": "${PREFIX}",
  "version": "${VERSION}",
  "published_at": "${timestamp}",
  "hostname": "${host}",
  "script_version": "${SCRIPT_VERSION}",
  "assets": [
    {
      "name": "${ASSETS[0]}",
      "upstream_url": "${UPSTREAM}/${ASSETS[0]}",
      "sha256": "${runtime_hash}"
    },
    {
      "name": "${ASSETS[1]}",
      "upstream_url": "${UPSTREAM}/${ASSETS[1]}",
      "sha256": "${devel_hash}"
    }
  ]
}
JSON

gh release create "$VERSION" --repo "$REPO" --title "GStreamer macOS ${VERSION}" \
  --notes "Unmodified upstream GStreamer ${VERSION} macOS installers. See manifest and provenance files for checksums and sources." \
  "${ASSETS[0]}" "${ASSETS[0]}.sha256" \
  "${ASSETS[1]}" "${ASSETS[1]}.sha256" \
  "$MANIFEST" "${PREFIX}-macos-${VERSION}.provenance.json"

echo "published release ${VERSION} in ${REPO}"
