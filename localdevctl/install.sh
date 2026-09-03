#!/usr/bin/env bash
# localdevctl bootstrap — public entry point for CFG's local dev tooling (devops-x).
#
#   curl -fsSL https://raw.githubusercontent.com/hihiapolla/tools-and-distribution/main/localdevctl/install.sh | bash
#
# Run from anywhere inside the git repository you want localdevctl injected into.
# The tool itself lives in the private hihiapolla/tollm repo (devops-x/); this
# script only sparse-clones it with YOUR git access (ssh key by default) and runs
# its installer. No tokens are involved — you are assumed to have repo access.
#
# Env: LOCALDEV_REF=main · LOCALDEV_HTTPS=1 (https + credential helper instead of ssh)
set -euo pipefail

SLUG="${LOCALDEV_REPO_SLUG:-hihiapolla/tollm}"
REF="${LOCALDEV_REF:-main}"
URL="git@github.com:${SLUG}.git"; [ "${LOCALDEV_HTTPS:-}" = 1 ] && URL="https://github.com/${SLUG}.git"

git rev-parse --show-toplevel >/dev/null 2>&1 || { echo "error: run this inside the git repository you want to inject into" >&2; exit 1; }

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
echo "==> Fetching ${SLUG}@${REF} (devops-x)"
if ! GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new' \
     git clone -q --depth 1 --filter=blob:none --sparse --branch "$REF" "$URL" "$TMP/repo" 2>"$TMP/err"; then
  echo "error: could not fetch ${SLUG}@${REF}" >&2
  sed 's/^/       /' "$TMP/err" >&2
  echo "hint: you need read access to ${SLUG} — set up an SSH key for github.com (check: ssh -T git@github.com)," >&2
  echo "      or use LOCALDEV_HTTPS=1 with a git credential helper." >&2
  exit 1
fi
git -C "$TMP/repo" sparse-checkout set devops-x >/dev/null
exec bash "$TMP/repo/devops-x/install.sh" "$@"
