#!/usr/bin/env bash
# localdevctl bootstrap — public entry point for CFG's local dev tooling (devops-x).
#
#   curl -fsSL https://raw.githubusercontent.com/hihiapolla/tools-and-distribution/main/localdevctl/install.sh | bash
#
# Run from anywhere inside the git repository you want localdevctl injected into.
# Downloads the release tarball for this OS/arch (native binary + bash tool + manifests),
# verifies its sha256, and runs the tarball's own install.sh → cli/localdev/ + cli/localdevctl.
# No auth, no git, no tokens: releases live on this public repo.
#
# Env: LOCALDEV_VERSION=x.y.z   pin a version (default: localdevctl/VERSION in this repo)
#      LOCALDEV_SRC=<checkout>  developers: install from a devops-x source checkout instead
set -euo pipefail

SLUG="${LOCALDEV_DIST_SLUG:-hihiapolla/tools-and-distribution}"
RAW="${LOCALDEV_DIST_RAW:-https://raw.githubusercontent.com/$SLUG/main/localdevctl}"
REL="${LOCALDEV_RELEASE_BASE:-https://github.com/$SLUG/releases/download}"

git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "error: run this inside the git repository you want to inject into" >&2; exit 1; }

if [ -n "${LOCALDEV_SRC:-}" ]; then
  exec bash "$LOCALDEV_SRC/install.sh"
fi

OS=$(uname -s | tr '[:upper:]' '[:lower:]'); ARCH=$(uname -m)
case "$ARCH" in x86_64) ARCH=amd64 ;; aarch64|arm64) ARCH=arm64 ;; esac
case "$OS-$ARCH" in darwin-arm64|darwin-amd64|linux-amd64|linux-arm64) ;; *) echo "error: no localdevctl build for $OS/$ARCH" >&2; exit 1 ;; esac

VERSION="${LOCALDEV_VERSION:-$(curl -fsSL --max-time 10 "$RAW/VERSION" | tr -d '[:space:]')}"
[ -n "$VERSION" ] || { echo "error: could not read $RAW/VERSION" >&2; exit 1; }
TAG="localdevctl-v$VERSION"
ASSET="localdevctl-$OS-$ARCH.tar.gz"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
echo "==> Downloading localdevctl $VERSION ($OS/$ARCH)"
curl -fsSL --retry 2 "$REL/$TAG/$ASSET" -o "$TMP/$ASSET" || { echo "error: download failed: $REL/$TAG/$ASSET" >&2; echo "hint: is release '$TAG' published on github.com/$SLUG/releases?" >&2; exit 1; }
curl -fsSL --retry 2 "$REL/$TAG/SHA256SUMS" -o "$TMP/SHA256SUMS" || { echo "error: SHA256SUMS missing from release $TAG" >&2; exit 1; }

want=$(grep " $ASSET\$" "$TMP/SHA256SUMS" | cut -d' ' -f1)
if command -v shasum >/dev/null; then have=$(shasum -a 256 "$TMP/$ASSET" | cut -d' ' -f1); else have=$(sha256sum "$TMP/$ASSET" | cut -d' ' -f1); fi
[ -n "$want" ] && [ "$want" = "$have" ] || { echo "error: sha256 mismatch for $ASSET (want ${want:-?}, have $have)" >&2; exit 1; }

tar -C "$TMP" -xzf "$TMP/$ASSET"
LOCALDEV_SRC="$TMP/localdevctl" LOCALDEV_TRANSPORT_LABEL=release bash "$TMP/localdevctl/install.sh"
