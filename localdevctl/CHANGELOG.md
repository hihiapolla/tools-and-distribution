# Changelog

Newest first. Each `## X.Y.Z` section is shown verbatim in the update banner of installs
older than that version — write entries for the person running `localdevctl`.

## 0.8.0 — 2026-09-05

### Added
- **Data survives `down`**: `~/.localdev/data` (`LOCALDEV_DATA`) is mounted into every kind node
  and bound through static PersistentVolumes (`manifests/storage/volumes.yaml`) for Postgres,
  the registry, Jenkins, n8n and DbGate. `down` keeps it, `down --purge-data` wipes it, `status`
  shows per-service sizes. **Needs one cluster recreate** (`down && up`, then `db deploy` once more).
- **Image registry** at `http://container-image-registry.local` (`registry deploy|status|catalog`,
  part of `up`): push from the host through the ingress, nodes pull the same ref via a containerd
  mirror (`hosts.toml` → own NodePort 30500) — works for Jenkins pushes and Argo CD pulls too.
  Plain http, so add it to Docker's `insecure-registries` once; `registry status` tells you.
- **Home page** `http://home.local`, also the ingress default so plain `http://localhost/` lands
  there: every UI, its login, the deploy command, and live up/down dots via `/probe/<name>`.
- **DbGate** (`app deploy dbgate`, `http://dbgate.local`, `admin` / `localdev123`): MIT web SQL
  client with ER diagrams; connection to the local Postgres preconfigured, every database visible.
- **MariaDB 10.11** (`mariadb deploy|status|cli`, part of `up`): `localhost:3306`, root / `mariadb`, on the data
  dir, tuned for Phabricator — shared by Phabricator and any MySQL-shaped service; browsable in DbGate.
- **Redis 7** (`redis deploy|status|cli`, part of `up`): `localhost:6379`, no auth, AOF on the data
  dir. **RedisInsight** as `app deploy redisinsight` → `http://redisinsight.local`, connection preconfigured.
- **Pub/Sub emulator** (`pubsub deploy|status|seed|topics`, part of `up`): official image,
  `PUBSUB_EMULATOR_HOST=localhost:8085`, REST at `http://pubsub.local`. The emulator is in-memory, so
  `pubsub seed PROJECT TOPIC[:SUB]…` records what you create in `~/.localdev/data/pubsub/seed.log`
  and `pubsub deploy` replays it. **Pub/Sub emulator UI** as `app deploy pubsub-ui` → `http://pubsub-ui.local`.
- **Phabricator** as `app deploy phabricator` → `http://phabricator.local`: **Phorge** (maintained fork,
  same Conduit API) + MariaDB 10.11. No maintained upstream image exists, so the app dir carries an
  `image/Dockerfile` that `app deploy` **builds and pushes to the local registry** — the first in-house
  image the registry serves. First registered user becomes admin. Databases go to the core MariaDB. Generic: any app with
  `image/Dockerfile` gets built + pushed the same way.
- **Camunda 7** as `app deploy camunda` → `http://camunda.local/camunda/app/` (`demo` / `demo`): Run 7.21 on
  the local Postgres — mamunda's engine generation, for BPMN/DMN and `/engine-rest` work.
- **Directus 11** as `app deploy directus` → `http://directus.local` (`admin@localdev.local` / `localdev123`):
  headless CMS / instant REST+GraphQL over its own Postgres db, uploads on the data dir.
- **Keycloak 26** as `app deploy keycloak` → `http://keycloak.local/admin/` (`admin` / `localdev123`): OIDC/SAML
  identity provider on the local Postgres. **Backstage 1.44** as `app deploy backstage` → `http://backstage.local`
  (guest sign-in): official example-app image, plugins as schemas in one db, example catalog preloaded.
- Upgrade rule documented (docs → Updates): only `kind-cluster.yaml` changes need `down && up`; anything else is
  `app deploy NAME` / `<group> deploy` / idempotent `up`.
- **Per-group help**: `localdevctl <group> help` (also `-h`/`--help`, and any unknown verb) lists that
  group's verbs with one-line explanations — `db help`, `pki help`, `app help`, …
- **Home page UX**: icon tiles per service; click opens a right-hand sheet with status, URL, login,
  ports, commands (copy) and a Launch button. `app list` now shows `installed` / `starting` /
  `not installed` per app.
- **Cheat sheet**: `docs/05-cheatsheet.md` + the same table at the end of `up` and `status`
  (URLs, logins, redeploy commands — no more hunting for the Redash password).

### Changed
- Positioning: `localdevctl` is a **generic** local development environment (one kind cluster with the
  databases, brokers, registry and tools your services need). CFG-specific bits are optional hooks:
  `blueprint/dbctl` seeding (any dir via `--blueprint`) and the Vault KV mount (`LOCALDEV_KV_MOUNT`,
  default unchanged). Wording updated in help, docs, README, home page; dev CA CN is now `localdev-ca`.
- `ingress hosts` line now includes `home.local`, `container-image-registry.local`, `pubsub.local`, `dbgate.local`,
  `redisinsight.local`, `pubsub-ui.local`. New host ports **3306** (MariaDB), **6379** (Redis) and **8085** (Pub/Sub) must be free.
- Jenkins and n8n get a `chown` init container (hostPath volumes ignore `fsGroup`).

## 0.7.0 — 2026-09-04

### Added
- **Argo CD** (`app deploy argocd`, `http://argocd.local`): upstream v2.12.6 install vendored,
  runs in its own `argocd` namespace in insecure mode behind the ingress; admin password set to
  `localdev123` on deploy. `argocd login argocd.local --plaintext --username admin`.
- **Jenkins** (`app deploy jenkins`, `http://jenkins.local`): LTS (JDK 17), setup wizard off,
  Configuration-as-Code with local admin `admin` / `localdev123`, plugins (git, pipeline,
  kubernetes, blueocean, …) installed by an init container on first start, `JENKINS_HOME` on a PVC.
- App framework: optional `manifests/apps/<name>/meta.sh` (`APP_NS`, `APP_DB=0`, `APP_SELECTOR`,
  `APP_WAIT`, `APP_MEM`), multiple `*.yaml` per app applied in order, own-namespace apps are
  removed by deleting the namespace. `app list` shows memory hints.

### Changed
- `release.sh` is now `./release` with `build [V]` · `package [V]` (build + tarballs + stage) ·
  `ship|publish [V]` (push + GitHub release) · `clean`.
- Ingress applies retry until the ingress-nginx admission webhook is reachable (fixes
  "connection refused" right after `up`).

## 0.6.0 — 2026-09-04

### Added
- **Ingress + hostnames**: ingress-nginx (pinned kind manifest, host :80/:443) with
  `grafana.local`, `loki.local`, `docs.local`, `vault.local`. `ingress deploy|status|hosts`;
  `hosts` prints the `/etc/hosts` line and sudo command. Part of `up`.
- **Apps** (`app list|deploy|status|delete NAME`): optional tools in `manifests/apps/<name>/`,
  each with its own Postgres role+db and `<name>.local` Ingress, deployed on demand:
  - **Redash** 10 (server/scheduler/worker + Redis) — schema, root user `admin@localdev.local` /
    `localdev123`, and a data source per local database, all automated.
  - **Metabase** v0.50 — setup wizard completed via API (same admin), every local database
    registered.
  - **n8n** 1.64 — Postgres-backed, PVC for `.n8n`, webhooks on `http://n8n.local`.
- **Docs site rebuilt on Docsify**: sidebar, full-text search, copy button on every code
  block, bash/yaml/sql highlighting, tabbed sections, prev/next pagination. Same `serve.py`
  (now a plain static server) and same in-cluster deployment. New pages: Ingress, Apps.

### Changed
- `kind-cluster.yaml` gains the :80/:443 mappings and the `ingress-ready` node label.
  **Existing clusters must be recreated** (`down` + `up`, then `db deploy`); `kube up`
  refuses to continue on a cluster without the mappings.
- `up` prints the ingress hostnames and the `app deploy` hint.

## 0.5.0 — 2026-09-04

### Added
- **Release pipeline**: `./release build|package|ship` — cross-compiles, packages one
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
