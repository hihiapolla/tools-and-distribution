# Changelog

Newest first. Each `## X.Y.Z` section is shown verbatim in the update banner of installs
older than that version — write entries for the person running `localdevctl`.

## 0.5.0 — 2026-09-04

### Added
- **Release pipeline**: `./release.sh build|package|publish|all` — cross-compiles, packages one
  tarball per OS/arch (binary + bash tool + manifests/seed/docs + install.sh, with SHA256SUMS),
  and stages `VERSION`/`CHANGELOG.md`/`SHA256SUMS` into the public
  `hihiapolla/tools-and-distribution` checkout. Pushing and uploading the GitHub Release
  (`gh release create localdevctl-v<version> …`, printed for you) stays manual.
- **Link mode** (like `npm link`): `localdevctl link [DIR]` makes every call run from a devops-x
  source checkout — `bun run cli/src/index.tsx` when bun is present, else the checkout's bash
  tool — with `.state`/`.certs` under the checkout. `unlink` returns to the installed copy.
  `LOCALDEV_SRC=<checkout>` does the same for a single invocation. Linked runs never offer updates.

### Changed
- Version check, `update` and the public bootstrap no longer need git or ssh: they read
  `localdevctl/VERSION` + `CHANGELOG.md` from the public distribution repo over https and
  download release tarballs (sha256-verified). `update` = re-run the bootstrap.
- `install.sh` (source installer) accepts a release tarball dir as `LOCALDEV_SRC` too, so the
  bootstrap and developer installs share one installer and one wrapper.

## 0.4.0 — 2026-09-04

### Added
- **Native binary edition begins** (`cli/`, TypeScript + React Ink, compiled with Bun into one
  self-contained executable per OS/arch). Ported so far: `doctor` (live checklist), `version`,
  `changelog`, `update`, `help`, and the update banner — now a boxed Ink panel with an inline
  `y/N` prompt. Every other command is delegated to the bash tool, unchanged.
- The `cli/localdevctl` wrapper prefers `localdev/localdevctl-bin` when present; set
  `LOCALDEV_BASH=1` to force the bash tool. Installs from a local checkout ship the binary when
  `cli/dist/localdevctl-<os>-<arch>` has been built (`bash cli/build.sh`); release downloads
  come in a later version.

### Fixed
- Self-update replaces the binary with write-then-rename so the running process is not killed.

## 0.3.0 — 2026-09-04

### Changed
- **Cluster renamed `cfg-dev` → `localdev`** (context `kind-localdev`) and new host port
  mappings. A leftover `cfg-dev` cluster is destroyed automatically by `kube up` / `up` and
  recreated as `localdev` (nothing in it is precious; re-run `db deploy` to reseed).
- **`up` no longer seeds databases.** It brings up infra only and prints the exact
  `db deploy` commands for this repo. Reason: blueprint bootstrap SQL is not re-runnable, so
  the old auto-seed was not idempotent.
- `db deploy` now runs bootstrap SQL **once** per database (ledger row `__bootstrap__`);
  migrations were already ledgered. Re-running is safe; `--recreate` rebuilds.

### Added
- `localdevctl monitoring deploy|status` — Loki + Promtail (all pod logs) + Grafana with the
  Loki datasource provisioned; Grafana `http://localhost:3000`, Loki `http://localhost:3100`.
  Part of `up`.
- `localdevctl docs` is now an in-cluster Deployment at `http://localhost:8088` (ConfigMaps
  built from the installed files, `python:3.12-alpine`, no image build). `docs serve [PORT]`
  keeps the local-process mode.
- `localdevctl doctor` — checks docker/kind/kubectl/psql/… and prints install steps for
  macOS (Homebrew) or Linux (static binaries, apt, docker group, inotify limits).
- Browser opening works on Linux too (`xdg-open`).

### Fixed
- `--blueprint DIR` was silently ignored (parsed in a subshell) — `db deploy DB --blueprint DIR`
  now works, which is how you seed a db in a repo without `blueprint/dbctl`.
- Promtail discovered 0 pods: it adds a `spec.nodeName=$HOSTNAME` selector, so `HOSTNAME`
  is now the node name (same workaround as the Grafana Helm chart).

## 0.2.2 — 2026-09-04

### Changed
- One-liner install is back: `curl -fsSL https://raw.githubusercontent.com/hihiapolla/tools-and-distribution/main/localdevctl/install.sh | bash`.
  The public bootstrap sparse-clones tollm with your git access and runs `install.sh`.

## 0.2.1 — 2026-09-04

### Changed
- No more GitHub token / PAT handling anywhere. The source repo is private, so the version
  check, `update` and the installer now use your own git access: `git ls-remote` over ssh
  (or https via credential helper with `LOCALDEV_HTTPS=1`), sparse-cloning `devops-x/`
  only when the remote moved. You are assumed to have read access to the repo.
- Install one-liner is now a sparse `git clone` + `bash devops-x/install.sh`
  (the raw.githubusercontent `curl | bash` form cannot reach a private repo).
- `install.sh` detects when it runs from inside a checkout and installs from it.

## 0.2.0 — 2026-09-04

### Added
- Update banner: when a newer version exists, every run shows current → latest, the
  changelog entries in between, and (on a terminal) asks `Update now? [y/N]`. Default is
  no; `y` runs the installer and re-executes your command on the new version.
- `localdevctl changelog [--remote]` — local changelog, or only what an update would bring.
- `localdevctl docs [PORT]` — local documentation site (`docs/`, stdlib server, default :8088).
- `CHANGELOG.md` (this file) and `docs/` are now part of the installed payload.

### Changed
- `version` states "up to date" / "update available" instead of only printing the latest.
- Offline version checks retry after 1 h instead of 24 h.

## 0.1.0 — 2026-09-04

### Added
- `install.sh` one-liner: injects `cli/localdev/` + `cli/localdevctl` (gitignored) with
  transport auto-detection (local checkout → `$GITHUB_TOKEN` → ssh → anonymous HTTPS).
- Throttled (24 h) version check with a stderr note; `version` and `update` commands.
- Repo-aware seeding: `up` / `db deploy` creates + migrates every
  `blueprint/dbctl/*/dev/spec.yml` database in the host repo.
- devops-toolkit-shaped verb tree: `kube`, `db instance|database|deploy|query|list`,
  `pki vault deploy|seed|kv|auth cert`, `pki certs issue|list`.
