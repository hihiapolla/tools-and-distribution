#!/usr/bin/env bash
# java-x bootstrap — public entry point for CFG's multi-repo Java VS Code extension.
#
#   curl -fsSL https://raw.githubusercontent.com/hihiapolla/tools-and-distribution/main/java-x/install.sh | bash
#
# Run from anywhere. Downloads the universal .vsix (bundled jdt.ls for mac/linux/win),
# verifies its sha256, and installs it with the VS Code (`code`) or Cursor (`cursor`) CLI.
# No auth, no git, no tokens: releases live on this public repo.
#
# Env: JAVAX_VERSION=x.y.z        pin a version (default: java-x/VERSION in this repo)
#      JAVAX_EDITOR_CLI=<cli>     editor CLI to install into (default: first of code, cursor on PATH, else the CLI bundled in the VS Code / Cursor app)
set -euo pipefail

SLUG="${JAVAX_DIST_SLUG:-hihiapolla/tools-and-distribution}"
RAW="${JAVAX_DIST_RAW:-https://raw.githubusercontent.com/$SLUG/main/java-x}"
REL="${JAVAX_RELEASE_BASE:-https://github.com/$SLUG/releases/download}"

CLI="${JAVAX_EDITOR_CLI:-}"
if [ -z "$CLI" ]; then
  for c in code cursor; do command -v "$c" >/dev/null 2>&1 && { CLI="$c"; break; }; done
fi
# Not on PATH (the "Install 'code' command" step was skipped): use the CLI bundled inside the editor app.
if [ -z "$CLI" ]; then
  r="${_JAVAX_TEST_ROOT:-}"  # test hook only: re-roots the system paths below
  for b in "$r/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
           "$r/Applications/Cursor.app/Contents/Resources/app/bin/cursor" "$HOME/Applications/Cursor.app/Contents/Resources/app/bin/cursor" \
           "$r/usr/share/code/bin/code" "$r/snap/bin/code" "$r/usr/share/cursor/bin/cursor" "$r/opt/cursor/resources/app/bin/cursor"; do
    [ -x "$b" ] && { CLI="$b"; break; }
  done
  # Last resort (macOS): Spotlight finds the app wherever it lives, by bundle id (VS Code, Cursor).
  if [ -z "$CLI" ] && command -v mdfind >/dev/null 2>&1; then
    for id in com.microsoft.VSCode=code com.todesktop.230313mzl4w4u92=cursor; do
      while IFS= read -r app; do
        [ -x "$app/Contents/Resources/app/bin/${id#*=}" ] && { CLI="$app/Contents/Resources/app/bin/${id#*=}"; break 2; }
      done < <(mdfind "kMDItemCFBundleIdentifier == '${id%%=*}'" 2>/dev/null)
    done
  fi
  [ -n "$CLI" ] && echo "note: no code/cursor on PATH — using $CLI (to add it: Command Palette → \"Shell Command: Install 'code' command in PATH\"; Cursor → \"Install 'cursor' command\")" >&2
fi
[ -n "$CLI" ] && command -v "$CLI" >/dev/null 2>&1 || {
  echo "error: no editor CLI found (looked for: ${JAVAX_EDITOR_CLI:-code, cursor on PATH; the CLI inside Visual Studio Code.app / Cursor.app in /Applications, $HOME/Applications or via Spotlight; /usr/share/code, /snap/bin/code, /usr/share/cursor, /opt/cursor})" >&2
  echo "hint: VS Code → Command Palette → \"Shell Command: Install 'code' command in PATH\"; Cursor → \"Install 'cursor' command\"" >&2
  echo "hint: or set JAVAX_EDITOR_CLI=/path/to/code" >&2
  exit 1
}

VERSION="${JAVAX_VERSION:-$(curl -fsSL --max-time 10 "$RAW/VERSION" | tr -d '[:space:]' || true)}"
[ -n "$VERSION" ] || { echo "error: could not read $RAW/VERSION" >&2; exit 1; }
TAG="java-x-v$VERSION"
ASSET="java-x-$VERSION.vsix"

TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT
echo "==> Downloading java-x $VERSION"
curl -fsSL --retry 2 "$REL/$TAG/$ASSET" -o "$TMP/$ASSET" || { echo "error: download failed: $REL/$TAG/$ASSET" >&2; echo "hint: is release '$TAG' published on github.com/$SLUG/releases?" >&2; exit 1; }
curl -fsSL --retry 2 "$REL/$TAG/SHA256SUMS" -o "$TMP/SHA256SUMS" || { echo "error: SHA256SUMS missing from release $TAG" >&2; exit 1; }

want=$(grep " $ASSET\$" "$TMP/SHA256SUMS" | cut -d' ' -f1)
if command -v shasum >/dev/null; then have=$(shasum -a 256 "$TMP/$ASSET" | cut -d' ' -f1); else have=$(sha256sum "$TMP/$ASSET" | cut -d' ' -f1); fi
[ -n "$want" ] && [ "$want" = "$have" ] || { echo "error: sha256 mismatch for $ASSET (want ${want:-?}, have $have)" >&2; exit 1; }

echo "==> Installing into $CLI"
"$CLI" --install-extension "$TMP/$ASSET" --force </dev/null

# Warnings only — never fail or uninstall anything past this point.
if "$CLI" --list-extensions </dev/null 2>/dev/null | grep -qix 'redhat.java'; then
  echo "warning: redhat.java is installed — disable it (Extensions → Language Support for Java → Disable); it fights java-x's bundled jdt.ls" >&2
fi

# JDK 17+ runs the bundled jdt.ls. java-x also discovers JDKs itself (SDKMAN, JavaVirtualMachines).
jdk_major() { local v; v=$(sed -n 's/^JAVA_VERSION="\([^"]*\)".*/\1/p' "$1/release" 2>/dev/null || true); v=${v#1.}; echo "${v%%[._]*}"; }
found=""
for home in "${JAVA_HOME:-}" "$HOME"/.sdkman/candidates/java/* /Library/Java/JavaVirtualMachines/*/Contents/Home "$HOME"/Library/Java/JavaVirtualMachines/*/Contents/Home; do
  [ -n "$home" ] && [ -x "$home/bin/java" ] || continue
  m=$(jdk_major "$home"); [ -n "$m" ] && [ "$m" -ge 17 ] 2>/dev/null && { found="$home"; break; }
done
if [ -z "$found" ] && command -v java >/dev/null 2>&1; then
  m=$(java -version </dev/null 2>&1 | sed -n 's/.*version "\([^"]*\)".*/\1/p' | head -1 || true); m=${m#1.}; m=${m%%[._]*}
  [ -n "$m" ] && [ "$m" -ge 17 ] 2>/dev/null && found="$(command -v java)"
fi
[ -n "$found" ] || echo "note: no JDK 17+ found — java-x needs one to run jdt.ls (e.g. 'sdk install java 21-tem' via SDKMAN)" >&2

installed=$("$CLI" --list-extensions --show-versions </dev/null 2>/dev/null | grep -i '^cfg-indodana\.java-x@' | cut -d@ -f2 || true)
echo "==> java-x ${installed:-$VERSION} installed ($CLI). Reload the window: Command Palette → \"Developer: Reload Window\""
