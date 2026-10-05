# Changelog — Java X

All notable changes to the Java X extension. Versions up to 0.14.x were
reconstructed retroactively (no changelog was kept); from 0.15.0 on, every
release gets an entry when it ships.

## 0.93.0 — 2026-10-05

- **Source folders come from Gradle's own project list, so cermati-java-commons
  builds in the IDE again.** The flat classpath took every `src/` folder found
  on disk. cermati-java-commons' `settings.gradle` leaves out `:reactive-commons`,
  `:all-commons`, `:application-commons`, `:google-commons` and
  `:secrets-commons`, so Gradle never resolves their dependencies, yet their
  26 source folders were still added. jdt.ls then stopped with "The project
  was not built since its build path is incomplete … org.flywaydb.core.Flyway"
  and compiled none of the repo. Source folders now come from the module
  directories Install records in `index/<repo>.tasks.json` (103 → 77 for
  cermati-java-commons; midas only loses `buildSrc`, 254 → 253). Installs
  without that file still use the directory walk.
- **No more manual Generate Flat Classpath after Install or an upgrade.** A
  connected repo's `.classpath` was only written by Connect / Generate, never
  by Install or a language-server start, so a re-install or a new Java X
  version kept the old classpath until Generate was run by hand. The
  `.classpath` now carries a format stamp. It is regenerated when an Install
  finishes, and before every language-server start if the index is newer, the
  stamp is old, or the source folders on disk changed.
- **Annotation-processor output is on the classpath.** JPA metamodel classes
  (`Item_`, `BaseDataEntity_`, about 130 Problems in midas) and MapStruct impls
  exist only under `build/generated/sources/annotationProcessor/java/{main,test}`,
  which Java X skipped. Those folders are now added when a local compile has
  produced them (midas: 75), as optional entries, so a later `gradle clean`
  doesn't break the build path. Java X runs no Gradle to create them. They add
  no duplicate classes in midas or cermati-java-commons.
- **Run/Debug from the editor works like the Main Classes view.** The main()
  Run/Debug lens and F5 (no launch.json) now find the owning repo from the
  source file (deepest Gradle root) and launch through the Gradle runner.
  Before, a file jdt.ls held in its default project had no project name, so
  the launch fell back to the jdt classpath and failed with "Main class … isn't
  unique in the workspace". jdt-classpath launches now always pass a connected
  repo's project name (quick pick when several repos declare the class), and a
  file outside every repo (e.g. a `.worktrees` copy) gets a clear message.
- **No more false "the build failed" before a jdt launch.** The pre-launch
  build check sent the debug plugin a malformed argument, so it threw on every
  jdt launch and reported a failed build.

## 0.92.0 — 2026-10-05

- **Plugins from the Gradle Plugin Portal resolve again.** Gradle only uses
  its built-in Plugin Portal while `pluginManagement.repositories` is empty;
  the repositories init script made it non-empty, so the portal disappeared
  and a build that relies on it could not apply its plugins. Install of
  `midas/documentprotection` failed with `Plugin [id:
  'io.github.cdsap.talaiot', version: '1.5.3'] was not found`. The init
  script now adds `gradlePluginPortal()` first when the build declares no
  plugin repositories, and only appends ours when it declares its own. The
  same applies to `buildSrc` (it gets the init script too), e.g. a
  `kotlin-dsl` buildSrc.
- **Main Classes explains an empty view.** Instead of showing nothing, it now
  shows one row with the reason and a click action: language server not
  running (starts it), no repo installed in this window (Install), installed
  but not connected (Connect). Each window has its own `.javax`, so a window
  opened on a nested build such as `midas/documentprotection` starts with
  nothing installed. The row also shows under a Running section, where the
  welcome text can't. A failed main-class search (`vscode.java.resolveMainClass`)
  now shows its error as a row (click retries) and logs it to the Java X
  output, instead of reading as "0 main classes". The row updates when an
  Install finishes.

## 0.91.0 — 2026-10-05

- **Per-project Gradle JDK.** Gradle no longer runs every project on the one
  workspace JDK. When a build declares a Java level (toolchain
  `JavaLanguageVersion.of(N)` or `sourceCompatibility`, including `buildSrc`
  convention plugins) above the workspace JDK, Java X runs that project's
  Gradle on the lowest installed JDK that meets it. Fixes Install of
  `midas/documentprotection` failing with `Run this build using a Java 21 or
  newer JVM` while midas stays on its JDK 11. A project the workspace JDK
  already satisfies is never moved. If no installed JDK meets the level, Java X
  warns with the version it needs and falls back to the workspace JDK.
- **Set Gradle JDK…** on a project (Projects view or Runtime → Gradle) writes
  the new `javaX.projectJavaHomes` setting (project path → JDK home), which
  wins over the automatic pick; **Automatic** clears it. `javaX.javaHome`
  stays the workspace default.
- Install, Gradle Tasks, Run/Debug builds, tests and the app JVM of a Run all
  use the project's JDK (a Run/Test Configuration JDK still overrides it). The
  Gradle ↔ JDK compatibility warning now checks the JDK actually chosen.
- Runtime → Gradle shows `wrapper X.Y · JDK N` per project (tooltip: path,
  source, declared level); the Install log line reads
  `JAVA_HOME: <path> [<source>]`; Diagnostics lists every project's JDK;
  Runtime's "Bootstrap JDK" row is now "Workspace Gradle JDK".

## 0.90.0 — 2026-10-05

- **Nested Gradle builds are their own projects.** A folder with its own
  `settings.gradle(.kts)` inside another build (e.g. `midas/documentprotection`,
  which midas does not include) used to be invisible: the scan stopped at the
  outer build, and the outer build listed the inner one's folders as modules
  and put its `src/` folders on its own classpath. Now the inner build gets its
  own row in the Projects view (`· nested in <parent>`), installs, connects
  and runs with its own Gradle wrapper, and the outer build's modules,
  source folders and tests stop at it. `buildSrc` is never a project or a
  module. Files map to the deepest project that contains them (test CodeLens,
  Show in Project Explorer, Class Test Lab, dashboard main classes, Class
  Inspector). Run **Refresh** on the Projects view after adding a nested
  `settings.gradle`.
- **Java level from toolchains.** The connected project's Java level now also
  reads `JavaLanguageVersion.of(N)` from the build files and `buildSrc`
  convention plugins, so a toolchain-only build (no `sourceCompatibility`)
  compiles as Java 21 instead of falling back to Java 11.

## 0.89.0 — 2026-10-05

- **Fix: a failed update check no longer waits 24 h.** 0.88.0 stored the
  "last checked" time as soon as `VERSION` was read — before the download. If
  `VERSION` went out before the release `.vsix` existed (or the download
  failed), clients skipped that release for a day. Now only a finished check
  (up to date, installed, or notified) starts the 24 h wait; a failed one is
  retried after about an hour.
- **Reload recommended after an update.** A background install now says
  "Java X <ver> installed. Reload the window to use it." with **Reload
  Window**, **Restart Extensions** and **What's New**. Because notifications
  get dismissed, a status-bar item `Java X <ver> — reload` stays until you
  reload (click it to reload). After the reload, "Java X updated to <ver>"
  appears once, with a link to the release notes.
- **Version in the Runtime view.** A top row `Java X <ver>` shows the update
  state: `up to date · checked 2h ago`, `<ver> available`,
  `<ver> installed — reload pending` or `update check failed` (the tooltip has
  the error). Inline buttons: Check for Updates, Open Dashboard.
- **Java X: Open Dashboard** (home icon on the Runtime view). One page with:
  version & updates (running / latest / last check, the `javaX.autoUpdate`
  mode, Check now, Reload), getting started (JDK 17+, disabling redhat.java,
  the manual-import + plug-icon flow, Maven repositories and certificates),
  what's new (this version's changelog section) and every Java X command,
  runnable from the list.
- **Release script** `./release package|ship [VERSION]` builds the `.vsix`,
  `SHA256SUMS` and release notes, stages `VERSION` in tools-and-distribution,
  and ships the GitHub release **before** pushing `VERSION`, so clients never
  see a version whose `.vsix` is missing.
- Installs on 0.88.0 update to 0.89.0 with 0.88.0's updater (the old single
  **Reload** prompt); the new prompt applies from 0.89.0 on.
- **Docs: troubleshooting + AI help in the README.** An "If you are an AI assistant"
  section, where to look (changelog, settings, output channels, on-disk state), a
  settings reference table matching `package.json`, and step-by-step fixes for
  Install/Connect, Gradle ↔ JDK version mismatches, jOOQ / generated classes that
  "cannot be resolved" (`src/generated/java` vs `build/generated`), and the Cermati
  nexus over mTLS, now with a second `maven-public` repository entry for the Gradle
  plugins and artifacts proxied from there.

## 0.88.0 — 2026-09-29

- **Self-update.** Java X ships as a GitHub Release on
  `hihiapolla/tools-and-distribution`, not the Marketplace, so VS Code never
  updated it. The extension now checks the release itself: about 30 s after
  activation, then at most once every 24 h (the last-check time survives
  reloads). New setting **`javaX.autoUpdate`**:
  - `install` (default) — download the new `.vsix`, verify its sha256 against
    the release's `SHA256SUMS`, install it, then offer **Reload** ("Java X
    <ver> installed — Reload Window"). A checksum mismatch is never installed.
  - `notify` — only show "Java X <ver> available" with an **Update** button.
  - `off` — no automatic checks.
- **Java X: Check for Updates** checks right away (ignores the 24 h throttle
  and the setting) and always reports the result — up to date, installed, or
  why it failed. Automatic checks stay silent when offline or when github.com
  is blocked; the reason goes to the *Java X* output channel only.
- Only strictly newer versions are installed — never a downgrade.
- Installs of 0.87.2 or older have no updater: re-run the install one-liner
  once to get 0.88.0; later releases arrive on their own.

## 0.87.2 — 2026-09-11

- **Fix: implementation hints pointed at stale lines after the implementation
  changed.** The inlay-hint cache is keyed by the *interface* document's
  version, but every hint embeds `Location`s into the *implementing* files.
  Editing, moving or rewriting an implementation on disk left the interface's
  version untouched, so its cached hints kept the old ranges — hovering the
  hint previewed the wrong token and Cmd+click landed a few lines off ("the
  resulting class is shifted"). Each cache entry now records the target URIs
  it points at; a change to any target (`onDidChangeTextDocument`, a
  `**/*.java` file-system change) drops the entries naming it and re-pulls
  after a 400 ms debounce, while create/delete/rename clear the whole cache.
  No jdt.ls restart needed anymore.

## 0.87.1 — 2026-08-28

- **Fix: conflicting jar versions resolved oldest-first.** When a repo's
  modules pin different versions of one artifact (athena: pubsub v1
  `subscriberframework-core-0.0.1-SNAPSHOT` vs v2 `1.0.0`, same FQCNs), the
  flat classpath listed them alphabetically, so jdt.ls resolved the OLD class
  and flagged correct v2 overrides as errors. The index path now orders
  same-artifact jars newest-first (JDT resolves a duplicated FQCN from the
  first jar). Both jars stay on the path — disjoint-package duals (midas's
  swagger-annotations 1.6.x + 2.x) must keep resolving. Reconnect the repo to
  regenerate its `.classpath`.

## 0.87.0 — 2026-08-28

- **Dot-entries now show in folders mode.** The tree used to hide everything
  dot-prefixed, which erased CFG deploy trees (`.services.d`, `.config.d`) and
  dotfiles (`.gitignore`). Now only a noise blocklist is hidden: `.git`,
  `.gradle`, `.idea`, `.javax`, `.worktree`, `.DS_Store`. The live-refresh
  watcher filter follows the same rule.

## 0.86.0 — 2026-08-28

- **Cut / Copy / Paste in the Project Explorer.** Tree-local file clipboard
  (files & folders): Paste appears on folder-ish rows only while something is
  on the clipboard; name collisions resolve VS Code-style (`name copy.ext`);
  pasting a folder into itself is refused; cut clears after paste.
- **Reveal in File Explorer** — jumps to the row's file in the built-in
  Explorer view (complements Reveal in Finder).

## 0.85.0 — 2026-08-28

- **Generic file-explorer context menu in the Project Explorer.** Right-click
  now offers the built-in Explorer staples: New File…, Copy Path, Copy
  Relative Path, Rename…, Open in Integrated Terminal, and Find in Folder…
  (Reveal in Finder and Delete already existed). Rename on a `.java` file
  reminds that the class name inside is not renamed.

## 0.84.1 — 2026-08-27

- Method hints now read `implemented in: FooImpl#findById, BarImpl#findById`
  — each link shows `Class#method` instead of just the class name (the
  jdt.ls parameter list is stripped from the method name).

## 0.84.0 — 2026-08-27

- **Per-method implementation hints in interfaces.** Each method of an
  interface now gets a grayed `implemented in: FooImpl` inlay at the end of
  its signature line; Cmd+click a class name to jump straight to the
  implementing METHOD (not just the class — jdt.ls's implementation provider
  resolves the exact override). Same truncation (+N more → peek all),
  caching, and warm-up-heal behavior as the existing type-level hints.
  jdt.ls's own implementations CodeLens only covers type declarations, so
  this fills the per-method gap.

## 0.83.0 — 2026-08-27

- **Reveal in Java X Project Explorer is back** (dropped in the 0.77.0
  architecture migration, lived only in the groot line since): on the
  editor-tab right-click menu (`editor/title/context`, next to VS Code's own
  "Reveal in Explorer View") plus the retitled editor-submenu/palette entry.
- **The Project Explorer is live again** — a created or deleted file shows up
  without Refresh (workspace-wide watcher, create+delete only, 300 ms
  debounce, build-output/dot-dir filtering via
  `surfaces/explorer/utils/watch-filter.ts`).
- **The two lines are converged:** office 0.83.0 and groot 0.83.0 now carry
  identical sources (publisher + changelog history remain the only deltas).

## 0.82.0 — 2026-08-27

(0.81.0 is the groot-line release that ported 0.79–0.80; skipped here.)

- **Build JDK picker in the Run Config panel.** Third select under Gradle:
  the JDK the phase-1 Gradle build (daemon) runs on — for simulating
  Gradle × JDK combinations easily. Default stays the workspace default JDK,
  so nothing changes unless you opt in; the "Java runtime" pick still shapes
  only the phase-2 app JVM. Persisted as `buildJavaHome` in
  `.javax/launch/<fqcn>.json` → `LaunchOverrides.buildJavaHome` → phase-1
  `JAVA_HOME` in both the command preview and the real Run/Debug build.
  Pair it with the Gradle pick — old Gradle can't run new JDKs.

## 0.80.0 — 2026-08-27

- **Run Config + Test Config panels restored to the pre-groot visual design —
  on the React + tlstack stack** (the string-HTML originals stay deprecated;
  current button styling kept, per decision).
  - **Test Config back to the old layout:** compact 3-card config row up top
    (Java runtime / env / test JVM args), then FULL-WIDTH tabs
    TESTS | OUTPUT | REPORTS with a run-state chip (RUNNING… / PASSED — exit 0 /
    FAILED — exit N). The TESTS pane is the real tree again — module → package
    → class with collapsible groups (expansion survives live re-renders, big
    scopes start packages folded), pass/fail aggregate chips, per-method
    durations, clickable failure messages that jump to the failing line, and
    the queued→↻→✓/✗ dimming during a run (baseline snapshot at run start).
    Reports show age + OPEN IN BROWSER / OPEN XML / REVEAL. Output no longer
    steals the tab on every chunk; a run only pulls you off REPORTS.
  - **Run Config regains the old chrome:** shell-syntax-highlighted
    reproducible commands (env/flag/task/string/continuation tokens colored,
    textContent-safe), the env mini-editor with a scroll-synced line-number
    gutter, and the DEFAULT chip + caret on the JDK and Gradle selects.
  - New shared `webviews/components/config-fields.tsx` (ShellText, EnvEditor,
    DefaultSelect); ported CSS in `webviews/index.css`. Test Config also gets
    the 0.79.0 stale-closure save fix. Verified with a jsdom smoke render of
    the built bundles (19 checks).

## 0.79.0 — 2026-08-27

(0.78.0 is the groot-line release that ported the office features; skipped here.)

- **Fix: Run Config saved the PREVIOUS change, not the one you just made.**
  The debounced save captured field values from the render the change handler
  ran in — before React committed the new value — so picking a Java runtime
  persisted the prior pick and the reproducible commands appeared not to
  update (they faithfully showed the wrongly-saved config). Save payloads now
  read a latest-values ref at send time; the toggles' `setTimeout(queueSave, 0)`
  workaround is gone.
- **Gradle picker in the Run Config panel.** New "Gradle" select under Java
  runtime — build (phase 1) only: repo default (wrapper → cached dist, with
  the detected version) or any version cached under `~/.gradle/wrapper/dists`
  (newest first, `-bin`/`-all` deduped). Persisted per main class as
  `gradleDist` in `.javax/launch/<fqcn>.json`, honored by both the command
  preview and the real Run/Debug build via
  `LaunchOverrides.gradleLauncher` → `resolveGradleLauncher({ launcherOverride })`.
  A configured-but-missing launcher fails loud with a pointer back to the
  panel. New `listGradleDists()` + tests (296 total, green).

## 0.77.1 — 2026-08-27

- **Fix: configured Maven repositories broke every Gradle run.** The generated
  repos init-script called bare `maven { … }` inside `javaXAddRepos`; Groovy
  resolves that against the closure's owner (the init script → `DefaultGradle`),
  not the passed repository handler — so any configured repository failed
  configure with "Could not find method maven() … on build … of type
  DefaultGradle" on every Gradle version. Now `repohandler.maven { … }`.
  Verified against the real cached Gradle 6.3 dist (repo lands as
  `cermati-nexus`). Regression assertion added to materialize-repos tests.

## 0.77.0 — 2026-08-27

- **Architecture migration: adopted the groot java-x line (0.73.0–0.76.0) as the new
  base.** Component composition root (`src/component/java-x-extension.component.ts`,
  manual DI), `src/services/` (headless model) + `src/surfaces/` (VS Code registration)
  split, Zod IPC (`src/shared/messages.ts` + `src/core/ipc/`), and React + tlstack
  webviews under `src/webviews/` replacing the string-HTML panels. All groot-line
  features below (0.73.0 2026-08-09 through 0.76.0) are included.
- **pkictl certificate config → Maven repositories.** `javaX.configureCertificate` now
  opens **Manage Maven Repositories**; re-add the corp Nexus as a repository with
  auth `mtls` pointing at the pkictl PEM cert/key (one-time setup — the old
  auto-discovered cert setting is not migrated).
- **Not carried over (by decision):** the office-line 0.73.0 (2026-08-27) features —
  "Reveal in Java X Project Explorer" on the editor-tab menu and the live
  (FileSystemWatcher-driven) Project Explorer refresh. The office-line 0.73.0 entry
  below this one refers to the groot line; the dropped entry lives in git history
  (commit `1860761`).
- Publisher stays `cfg-indodana` (upgrade path for the installed extension); the groot
  line uses `tolim`.

## 0.76.0 — 2026-08-23

- **Inlay hints on classes:** `extended by: Foo, Bar` beside a class name
  (same Cmd+click / `+N more` peek as the existing interface
  `implementation found:` hint). Leaf classes with no subtypes stay bare.

## 0.75.11 — 2026-08-09

- **Blue cup brand package** (`icons/icon-master.svg` + raster set): marketplace
  icon is `media/icon.png` (from `icon-256.png`); activity-bar marks
  (`media/java.svg`, `explorer.svg`, `run.svg`) redrawn to the cup mark.
  Source set stays in `icons/` (excluded from the VSIX).

## 0.75.10 — 2026-08-09

- **Project Explorer folders mode:** default folder icons (no bare chevrons);
  `build` / `bin` / `out` / `target` / `classes` folded under a collapsed
  **build outputs** row.
- **Gradle Tasks** uses a Gradle elephant icon (view + tree rows).

## 0.75.9 — 2026-08-09

- **Clean Unused Imports** in the Java X editor context menu (organize imports
  via the language server).
- **JVM Inspector Threads:** optional **Group by name** view — pools like
  `http-nio-8080-exec-*` and `RMI TCP Connection(*)` collapse under one group
  with counts / state summary; expand for individuals.
- **Test Config layout** matches Run Config: two-column shell (Launch
  configuration cards on the left, Tests/Output/Reports on the right).

## 0.75.8 — 2026-08-09

- **Fix: Lombok (and other compileOnly) missing from Install classpath.**
  `javax.init.gradle` preferred `testCompileClasspath` over `compileClasspath`.
  On Spring Boot / Gradle 8 multi-module builds, `testCompileClasspath` often
  omits `compileOnly` — so `import lombok.*` never resolved even with the
  Lombok jdt.ls agent. Install now always unions `compileClasspath`,
  `testCompileClasspath`, `annotationProcessor`, and the runtime graph.
  **Re-run Install / Bootstrap** on affected repos, then reconnect / restart LS.

## 0.75.7 — 2026-08-09

- **JFR GC & Heap: clearer timeline.** GC pause list columns are labeled
  (AT +t, wall clock when recording Start is parseable, PAUSE). Heap chart
  draws dashed amber ticks at each GC. Times are relative to the first sample
  in the recording series (`t`), not only unlabeled seconds.

## 0.75.6 — 2026-08-09

- **JAR Viewer Members tab shows params + return types.** React expected
  `signature`/`modifiers`; host `parseJavapMembers` posts `params`/`ret`/`mods`
  (and field `value`). Restored `name(params): Ret` layout with modifiers.

## 0.75.5 — 2026-08-09

- **JAR Viewer Javadoc tab renders structured docs again.** React expected a
  simplified `classDoc` / `methods[].name|doc` shape; the host still posts
  `JavadocInfo` (`classParagraphs`, chips, method signatures, DocSeg runs,
  @param/@return). Empty cards were that mismatch — restored full render.

## 0.75.4 — 2026-08-09

- **JAR Viewer Source tab syntax highlight.** Ported `.j-kw` / `.j-str` / `.j-cmt`
  / `.j-doc` / `.j-ann` / `.j-num` token styles into the React webview CSS (host
  already emitted highlighted HTML; styles were only on the old HTML panel).

## 0.75.3 — 2026-08-09

- **JAR Viewer opens any `*.jar` file.** Registered as a custom editor (default
  for `.jar`, same pattern as JFR): double-click in Explorer, Open With, context
  menu, command palette **Java X: Open JAR…**, or the JARs tree. Works for
  workspace JARs, not only the `.javax/libs` catalog.

## 0.75.2 — 2026-08-09

- **Fix blank MBean Browser:** React surface expected `types`/`name` but host
  `buildMBeanTree` sends `groups`/`label` — tree apply crashed the webview.
- **Fix invisible Run Config toggles:** tlstack `Switch` uses `hsl(var(--primary))`
  while theme tokens pointed at VS Code hex colors (invalid). Restored HSL
  component tokens for dark/light and replaced Switch with a native `jx-switch`.
- **Harden JFR/JVM charts:** ResizeObserver + rAF redraw, defensive report
  defaults, canvas size fallbacks, empty-state labels when no samples yet.

## 0.75.1 — 2026-08-09

- **JFR Viewer + JVM Inspector feature parity with the old HTML panels.**
  - JFR: host posts the full `buildJfrReport` (flame trie, heap/CPU series,
    allocs/errors/locks) instead of a flattened shell. React surface restores
    Flame Graph (canvas icicle, zoom/highlight), GC & Heap charts, Hot Methods
    bars, and Allocations & Errors tabs.
  - JVM Inspector: live rolling canvas charts (heap/classes/threads/CPU), full
    Memory pools / Classes histogram / expandable Threads / GC collectors +
    live events / System KV panels, Pause · GC · Heap Dump · Browser actions.
  Browser dual-view still serves the legacy HTML from `jvm-inspector.html.ts`.

## 0.75.0 — 2026-08-09

- **Remaining panels on React + tlstack** (old layout language preserved):
  Project Dashboard, JAR Viewer, Test Config (TESTS/OUTPUT/REPORTS tabs),
  MBean Browser, JFR Viewer, JVM Inspector. Hosts still drive free-form
  postMessage payloads; webviews use loose raw IPC + VS Code theme chrome.
  Legacy `*.html.ts` left as deprecated references for browser-side JVM
  inspector server HTML only.

## 0.74.2 — 2026-08-09

- **Clean & Restart confirms first.** `javaX.cleanLanguageServer` (LS Dashboard button
  and Runtime tree) shows a modal warning before wiping jdt.ls workspace data.

## 0.74.1 — 2026-08-09

- **React panels keep the old layout language.** LS Dashboard, Class Test Lab, and
  Run Config still use `@tlstack/tlstack-ui` primitives, but chrome matches the
  pre-migration panels: VS Code theme tokens, status card + actions, key/value
  cards, two-column Run Config (launch cards + numbered shell steps), debounced
  symbol search, JFR/JMX toggles restored.

## 0.74.0 — 2026-08-09

- **Wave 0 complete (architecture TDD):**
  - `src/modules/` → **`src/services/`** (model) + **`src/surfaces/`** (VS Code registration).
  - **`GradleProcessService`** — shared prepare/spawn path; Install uses it for repo
    materialization + launcher resolution; Run/Test use `materializeRepos()`.
  - Composition root constructs `RepositoryService` + `GradleProcessService` and
    injects narrow deps into surface registrars.
- **React + `@tlstack/tlstack-ui` webviews (first cut):**
  - Dual-target esbuild (host `dist/extension.js` + browser `dist/webview/*.js`).
  - Host IPC: `core/ipc/{webview-html,webview-host,ipc-host,react-webview}` +
    Zod messages in `shared/messages.ts`.
  - Migrated surfaces: **LS Dashboard**, **Class Test Lab**, **Run Config**.
  - Remaining string-HTML panels marked `@deprecated` (jar viewer, JFR, JMX,
    JVM inspector, test-config, project dashboard) — host logic intact; migrate
    next on the React shell.
  - Tailwind v4 + tlstack tokens; React dedupe for `file:` tlstack link.
- Skipped CFG-only `.services.d` env presets (out of product scope).

## 0.73.0 — 2026-08-09

- **Fork from `references/tollm` java-x (0.72) into the tollm monorepo package**
  with Wave-0 architecture from the improved-architecture TDD:
  - **`JavaXExtensionComponent`** composition root (`src/component/`) —
    sole place that constructs the service graph and registers surfaces.
  - **`RepositoryService`** (`src/services/repository/`) replaces **pkictl**:
    user-configured Maven repositories (`none` | `basic` | `token` | `mtls`),
    secrets in VS Code SecretStorage, per-run temporary init-script injection
    via `--init-script` on Install / Run / Test / Gradle tasks.
  - Removed `javaX.pkictl.*` settings, pkictl discovery (`cert.ts`), and
    Runtime "pkictl Certificate" section → **Maven Repositories** section +
    `Java X: Manage Maven Repositories` / `Add Maven Repository`.
  - Publisher rebranded **`cfg-indodana` → `tolim`**.
- **Performance / architecture fixes while forking:**
  - **Stable mTLS keystore password** (SecretStorage) + keystore reuse when
    cert/key mtime unchanged → Gradle daemon reuse (random-per-run passwords
    used to spawn a new multi-GB daemon every Install).
  - Runtime view poll no longer calls `projects.fireChanged()` every 10s
    (that re-triggered main-class search storms).
  - `resolveGradleLauncher` accepts `extraInitScripts` so repository
    materialization is one place for all Gradle spawns.

## 0.72.0 — 2026-08-03

- **Class Test Lab (new sidebar view, first iteration).** A webview under the
  Java X container (next to the Class Inspector; also in the editor's Java X
  submenu and the palette) that tracks the active Java class and builds an
  **AI test-generation prompt** for it: full class source, the conventional
  test path (`src/test/java` mirror, `Test` suffix; extend-mode when the test
  already exists), the module's REAL test stack (TestNG/JUnit + Mockito etc.,
  detected from its existing test imports — majority wins), and the closest
  existing test as a style reference. Output contract: scenario plan first,
  then one compilable test class persisted at the conventional path.
  The prompt is saved to `.javax/testlab/<Class>-test-prompt.md` with
  **Copy Prompt / Copy claude -p Command / Open Prompt File** actions —
  provider select ships with Claude (`claude -p`). Next iterations: run the
  agent from the panel, preview the generated test, accept → persist + reveal
  in the Project Explorer.

## 0.71.0 — 2026-08-02

- **Connected Java Projects is now the "Java X - Project Explorer"** —
  container, view, and every command title renamed (the editor submenu entry
  reads **Show in Project Explorer**). The empty-state text now explains what
  the view is: every repo that has been **Installed and Connected to the
  Java X language server (jdt.ls)**, with pointers to do both.
- **Folders is the default mode** (packages stays one toggle away) — the
  file tree matches what the New Class / Delete / New Folder actions operate
  on.
- **Reveal in Project Explorer (Folders)** on package rows: jumps from a
  flattened package straight to its directory in the folder tree (switches
  the mode and reveals).

## 0.70.0 — 2026-08-02

- **Keyboard shortcuts in Connected Java Projects** (while the view has
  focus): **⌘⌫ / Ctrl+Delete** deletes the selected row (class, package, or
  folder/file — same confirms as the menu), **⌘N / Ctrl+N** creates a class
  in the selected package/module/folder (or next to the selected class),
  **⌘C / Ctrl+C** copies the row's name (package name, class FQN, path).
- **Generate Getters/Setters… and equals()/hashCode()…** join Add
  Constructor in the editor's Java X submenu — Lombok-first (`@Getter`/
  `@Setter`/`@EqualsAndHashCode` as text edits) with the explicit
  jdt.ls-generated source variant behind a per-field picker
  (`java/generateAccessors` + `java/generateHashCodeEquals`, present in the
  bundled 1.61 but unwired until now). Regenerating over existing methods
  asks first.
- **Copy Fully-Qualified Name** — in the editor submenu (nested classes give
  the full `Outer.Inner` chain) and on class rows in the tree.
- **Fuller tree menus:** project rows get Open Project Dashboard + Reveal in
  Finder (they had no menu); module rows get Open build.gradle + Reveal;
  package rows get **Delete Package…** (modal confirm listing every source
  root dir — and the nested packages that go with it; the default package
  refuses); class rows get New Class… (sibling, same source root); folders
  get New Folder….

## 0.69.0 — 2026-08-02

- **Folders mode gets its context menu.** Right-clicking a folder in
  Connected Java Projects' folders view now offers **New Class…** (package
  derived from the `src/{main,test,generated}/java` root, same as packages
  mode), **Reveal in Finder**, and **Delete…** (files and folders, modal
  confirm, recursive, always to trash). Previously folder/file rows had no
  menu at all.
- **Show in Connected Java Projects.** New entry in the editor's Java X
  right-click submenu (and the palette): reveals the current file in the
  tree — as its class row in packages mode, as its file row in folders
  mode — expanding and focusing the view. The tree provider gained
  `getParent` to support reveal.

## 0.68.0 — 2026-08-02

- **All compile errors at once.** 0.67.0 surfaced the first compile error;
  now EVERY collected error lands in the **Problems panel** (source "Java X
  build", grouped per file, clickable, replaced on the next launch), the
  terminal shows up to 10 (was 3), and the notification says "N compile
  errors" with a **Show All Problems** button next to the jump-to-first one.
- **Test Config panel: tree + TESTS tab.** The scope panel's flat class list
  (431 rows on midas) is now a **module → package → class tree** — the
  typical test-runner structure: collapsible groups with rolled-up
  ✗/✓ aggregates and worst-status icons, expansion state preserved across the
  live 200ms re-renders, packages auto-folded on big scopes (>40 classes).
  The rows moved into a full-width **TESTS** tab alongside OUTPUT and
  REPORTS; launch-config cards sit in a compact row above. A run started
  while you're on REPORTS switches to TESTS so you watch the live tree
  (OUTPUT stays if you chose it). Webview jsdom-verified (17 checks).

## 0.67.2 — 2026-08-02

- **Extension icon.** java-x now has one — the green cup with the amber
  X-steam (256px PNG at `media/icon.png`; source set kept in `icons/`).

## 0.67.1 — 2026-08-02

- **JFR recordings open in the built-in JFR Viewer.** The "recording saved"
  notification (and the `Open JFR Recording…` palette command) still launched
  an external JDK Mission Control — a 0.50 leftover that errored on every
  machine without JMC, pointlessly since 0.57 shipped the built-in viewer
  (flame graph, hot methods, GC). Both now open the `.jfr` in the viewer;
  the notification button reads "Open Recording". The external-JMC launcher
  and the `javaX.jmcPath` setting are removed.

## 0.67.0 — 2026-08-02

- **Compile errors now say so.** When a run/test/task failed because the code
  doesn't compile, the terminal used to print a misleading generic hint (app
  runs: "Common cause: nexus mTLS…"; test runs: "TESTS FAILED — full report…")
  and left the developer to dig the real error out of the Gradle noise. javac
  diagnostics (`File.java:NN: error: message`) are now collected from the
  streaming build output (new `utils/javac-diagnostics.ts`, chunk-safe,
  deduped), and on failure the terminal prints the truth —
  `COMPILE ERROR — the code doesn't build, nothing was launched:` followed by
  up to 3 `File.java:NN — message` lines — plus a notification whose button
  jumps straight to the first failing line. The old hints remain only for
  failures with NO compile diagnostics (where they are actually likely).
  Applies to app runs (phase-1 build), test runs, and Gradle-task runs.
  Verified against a real broken build. 270 tests green.

## 0.66.0 — 2026-08-02

- **Fix: nested test classes silently ran NOTHING.** CFG's TestNG suites often
  nest (`class AbTestingServiceImplTest { static class FindVariation { @Test … }}`)
  — the runnable classes are `Outer$Nested`, so a `--tests` filter on the outer
  fqcn matched zero tests, and repos with `failOnNoMatchingTests false` (frodo)
  then exited 0 with an empty report. That was the "ran ABTestingServiceImpl
  test but no report" mystery. Every class/method filter now ships as a pair
  (`fqcn` + `fqcn$*`), results/aggregates/re-run-failed/reports all roll nested
  classes up under the outer class, and a run whose filter matches nothing now
  raises a loud warning instead of a fake green. Live-verified on frodo
  (Gradle 5.4.1): the nested tests run, markers stream, reports generate.
- **Reports are now guaranteed:** the init script force-enables Gradle's JUnit
  XML + HTML test reports (`required`, with the pre-6.1 `enabled` fallback) —
  repos that disable them for CI speed can't leave the Reports tab empty.
- **Test Config panel reworked:**
  - **Full-width OUTPUT | REPORTS tabs** below the config/methods grid. OUTPUT
    auto-activates when a run starts; REPORTS lists the generated artifacts
    (nested-class pages included, labeled).
  - **Testing-view-style live progress:** when a run starts, rows dim to a
    queued mark (◷), then flip live to ↻ / ✓ / ✗ as each test starts and
    finishes, with the aggregate chip updating — the Test-Explorer experience,
    per method.
  - **Repo/module panels:** clicking a repo or module row in Test Classes now
    opens the panel in scope mode — class rows with per-class aggregates
    (click one → its own class panel), RUN ALL / DEBUG ALL for the whole
    scope, scope-level launch config (own `.javax/launch/_scope.…` key), suite
    reports per module, and RE-RUN FAILED that groups failures into one Gradle
    run per module.
  - Webview jsdom-verified (21 checks, both modes). 263 vitest tests green.

## 0.65.0 — 2026-08-02

- **Test Config panel — the test-side Run Config.** Clicking a test class in
  the Test Classes view now opens a panel instead of the bare source file
  (source stays one click away: context menu + a link in the panel):
  - **Run & debug from the panel:** RUN ALL / DEBUG ALL in the header, RUN /
    DEBUG per method row, and RE-RUN FAILED when failures are recorded.
  - **Live, interactive run view:** per-method rows flip ✓/✗/↻ as markers
    stream in, with durations and one-line failure messages that jump to the
    failing line; a RUN OUTPUT console mirrors the raw Gradle terminal with a
    RUNNING…/exit chip. Runs started from the tree or CodeLens mirror into an
    open panel too.
  - **Reports, findable at last:** a REPORTS card lists what Gradle actually
    generated for this class — the class HTML page, the full suite index.html,
    and the JUnit XML — with timestamps, OPEN IN BROWSER, and REVEAL. No more
    digging through `build/reports/tests/test/…`.
  - **Per-class launch config:** env vars, test-JVM arguments, and JDK,
    persisted at `.javax/launch/<fqcn>.json` and applied to EVERY launch of the
    class (panel, tree, CodeLens, re-run failed). ★ env/JVM args reach the
    forked test JVM via the injected init script (`t.environment`/`t.jvmArgs`
    from JSON `-Djavax.test.env`/`-Djavax.test.jvmArgs`) — exporting vars
    around gradlew would never arrive: the forked JVM inherits the DAEMON's
    env, which is fixed at daemon start.
  - Live-verified: env + JVM args asserted from inside a real test JVM
    (simpsons, Gradle 7.4/TestNG); webview jsdom-verified (18 checks). 258
    vitest tests green.

## 0.64.0 — 2026-08-02

- **Test iteration → IntelliJ parity, wave 1 (Track B steps 1+2).**
  - **Per-method runs.** Test classes in the Test Classes view now expand into
    their `@Test` methods (regex scan — JUnit4 `@Test`/`@org.junit.Test` and
    JUnit5 `@ParameterizedTest`/`@RepeatedTest`/`@TestFactory`/`@TestTemplate`),
    each with inline Run/Debug that launches `gradle test --tests
    'com.x.MyTest.method'`. A new **test CodeLens** puts "Run Test | Debug Test"
    above every test method and "Run All | Debug All" on the class declaration —
    no LS dependency, lenses appear the moment the file opens.
  - **Live result tree.** A new `javax.test.gradle` init script rides every test
    launch and its listener prints one `javax-test: STARTED/PASSED/FAILED/SKIPPED`
    marker per test; the extension stream-parses the terminal feed into live
    ✓/✗/spinner state on method and class rows (and a third status lens with
    duration / one-line failure). After the run, results reconcile against
    Gradle's JUnit XML (`build/test-results/test/TEST-*.xml`) — exact statuses,
    failure messages, full stacks. Failed rows/lenses jump straight to the
    failing line (parsed from the stack frame).
  - **Re-run failed.** Classes with failures get a `$(debug-rerun)` inline
    action that re-runs ONLY the recorded failures as `--tests` method filters.
  - **`cleanTest` retired.** The init script sets `test.outputs.upToDateWhen
    { false }`, so `test` re-executes on unchanged code WITHOUT the clean —
    compile stays incremental, re-runs start seconds faster.
  - New pure utils + tests: `test-markers` (chunk-safe marker stream),
    `method-scan` (@Test discovery), `junit-xml` (report parser + failure-line),
    `test-scan.testEntryForFile` (editor file → test identity). 254 tests green.
- **Fix: outline/breadcrumb errors while typing** ("selectionRange must be
  contained in fullRange"). jdt.ls transiently returns invalid symbol ranges
  mid-edit and the language client's converter throws on them, failing the whole
  documentSymbol request with a status-bar error. A `provideDocumentSymbols`
  middleware now fetches the raw symbols, clamps selectionRange into fullRange
  (recursively, fixing inverted ranges too), and converts safely.

## 0.63.0 — 2026-08-02

- **Run Config: opt-in "Expose remote JMX" toggle.** Off by default (the
  built-in Inspector attaches with no flags and needs none of this) — turn it on
  only to point **external** tools (JConsole, VisualVM) or a remote connect at
  the app. When on, phase 2 gets the standard `-Dcom.sun.management.jmxremote.*`
  flags with **both** the registry and RMI export ports pinned to one value,
  `authenticate=false ssl=false`, bound to `127.0.0.1`.
  - **Port control:** leave it blank for **auto** (a free port is picked at
    launch, so concurrent runs never collide) or set a **fixed port** for a
    stable JConsole/firewall target.
  - **Transparency:** the exact flags appear in the panel's reproducible phase-2
    command, the `service:jmx:rmi:///jndi/rmi://127.0.0.1:<port>/jmxrmi` connect
    URL is shown (and printed to the run terminal at launch — important for the
    auto-port case), and the panel flags it as unauthenticated + plaintext,
    loopback-only. Persisted in `.javax/launch/<fqcn>.json` (`jmxRemote`/`jmxPort`).
  - Paste the URL into the MBean Browser's "Connect to a remote JMX URL…" or
    JConsole. Verified end-to-end: a JVM launched with these flags exposed a
    working endpoint that the bridge connected to and read live. New pure helpers
    `parsePort` / `jmxRemoteArgs` / `jmxServiceUrl` (+4 tests); 213 tests green;
    Run Config webview jsdom-verified.

## 0.62.0 — 2026-08-02

- **Open the JVM monitor in a browser, side-by-side with VS Code.** A new
  **Open in Browser** button in the Inspector header starts a tiny localhost
  server (bound to `127.0.0.1` on an ephemeral port) and opens the SAME
  dashboard in your default browser. It shares ONE bridge with the webview (no
  second attach): data streams over Server-Sent Events and Pause / Run GC /
  Heap Dump post back — so the browser view is fully live, not a snapshot. A
  late-opened browser is replayed the recent history so its charts aren't empty.
  The page is transport-agnostic (VS Code webview API when embedded, EventSource
  + fetch when served over http) and ships a dark-theme fallback so it looks
  right outside VS Code. Loopback-only + ephemeral-port keeps it a local dev
  affordance.
- **Refactor:** the Inspector's polling/actions moved into a reusable
  `JvmMonitorEngine` (multi-subscriber, with a `MonitorSnapshot` replay buffer,
  5 tests); the webview panel and the new `JvmMonitorServer` are thin adapters
  over it. No behavior change for the in-editor Inspector.
- 209 unit tests green; the server verified end-to-end over real HTTP (page +
  SSE snapshot/live + POST actions + 404) and the dual transport jsdom-verified
  in both webview and browser modes.

## 0.61.0 — 2026-08-02

- **Inspector: charts one-per-row + a new Process-CPU-over-time chart.** The
  Overview "Live" section is no longer a 3-across grid — Heap, Loaded classes,
  Threads and **Process CPU** each get a full-width row (taller, more legible).
  The CPU chart floors its axis at ~8% so an idle process reads as flat rather
  than noisy, and its tooltip shows process + system load.
- **Threads: per-thread memory + more detail.** Each thread row now shows its
  **allocated bytes** (cumulative, via HotSpot `getThreadAllocatedBytes`), and
  expanding a thread reveals priority, allocated total, blocked/waited counts
  (with times when contention monitoring is on), and the held lock + its owner.
  The list stays sorted by CPU time.
- **GC: a live "Recent collections" run list.** A new GC-notification listener
  in the bridge streams every collection as it happens; the GC tab lists them
  newest-first with **time, collector, cause, pause duration, space reclaimed,
  and heap before → after** (e.g. a `System.gc()` reclaiming 175 MB in 107 ms).
  The GC insight line now also totals the observed live reclamation.
- Bridge gains a `com.sun.management.ThreadMXBean` proxy (allocated bytes +
  blocked/waited time) and GC `GarbageCollectionNotificationInfo` listeners
  (registered on subscribe, removed on unsubscribe). ★ A gcEvent carries its own
  GC `id`, so the client now routes by `type` before request-reply id
  correlation. 204 tests green; webview jsdom-verified; the gcEvent stream and
  per-thread allocation live-verified against a JDK-11 daemon (a forced GC
  reported 183 MB reclaimed in 107 ms).

## 0.60.0 — 2026-08-02

- **JVM Inspector rebuilt as a tabbed monitoring dashboard** (Run Config visual
  language: status dot, pill actions, cards, colored chart fills; the MBean
  Browser is unchanged). Clicking the 📈 icon opens an **Overview** summary and
  five detail tabs:
  - **Overview** — live tiles + heap/classes/threads charts + a GC summary card
    and a plain-language insight line (heap of committed/max, total collections,
    idle hint).
  - **Memory** — heap used/committed/**max (Xmx)**/**init (Xms)** with % of max,
    the parsed **launch flags** (`-Xmx`/`-Xms`/`-Xmn`/`-Xss`/MaxMetaspaceSize +
    the collector) from `RuntimeMXBean.InputArguments`, and a **memory-pools**
    table (per-region used/committed/max/peak/% of max).
  - **Classes** — loaded/total/unloaded + live instances, and the top-classes
    table now shows each class's **% of live heap** alongside instances/Δ/bytes.
  - **Threads** — a detailed live **thread dump**: per-thread state, CPU time,
    daemon flag, held lock, and an expandable stack, plus a state breakdown and
    deadlock highlighting (via a new bridge `threads` command using a typed
    `ThreadMXBean` proxy).
  - **GC** — per-collector collections/total time/avg/**last pause** and the
    managed pools (from each collector's `LastGcInfo`).
  - **System** — VM name/vendor/version, JIT + total compile time, OS
    (arch/version/processors/physical memory/file descriptors), and the full
    input-argument list.
  - **Actions:** Pause/Resume the live polling, **Run GC**, and **Heap Dump**
    (invokes `HotSpotDiagnostic.dumpHeap` → `.javax/jmx/<app>-<stamp>.hprof`,
    behind a confirm). Chart cursors are now a hand pointer.
  - New bridge commands `pools` + `threads`; new pure `jvm-args` util (parse
    `-Xmx`/`-Xms`/… + byte/percent formatting, 9 tests). 204 unit tests green;
    the webview jsdom-verified across all six tabs; `pools`/`threads`
    live-verified against a running JDK-11 daemon. Falls back to jcmd-only (with
    the JMX-only tabs marked as such) when attach fails.
  - Note on concurrency: multiple simultaneous runs never collide — local
    `startLocalManagementAgent()` binds a per-JVM ephemeral loopback port and
    each Inspector spawns its own bridge; only remote JMX uses a fixed port.

## 0.59.0 — 2026-08-02

- **JMX integration — live MBean access without JConsole/VisualVM.** A new
  dependency-free **jmx-bridge** (JDK-only `com.sun.tools.attach` +
  `javax.management.remote`, ~16 KB jar built by `scripts/build-jmx-bridge.sh`,
  `npm run build-jmx`) speaks newline-delimited JSON over stdio — the same
  bundled-tool pattern as jdt.ls/jfr. The host spawns it with the **newest**
  installed JDK so it can attach into older 8/11 app JVMs (verified 21→11).
  Commands: `attach {pid}` (`startLocalManagementAgent` — no flags needed on the
  target), `connect {url}`, `mbeans`, `read`, `meta`, `invoke`, and a
  `subscribe` ticker streaming Memory/ClassLoading/Threading/GC/OperatingSystem
  MXBeans.
  - **JVM Inspector now prefers JMX** (was jcmd-only). Heap, **loaded-class
    count**, threads, GC and process CPU come from cheap 2 s MXBean polls (no
    safepoint pause), so the charts update smoothly; the slow
    `jcmd GC.class_histogram` is kept ONLY for the top-classes-by-retained-bytes
    table (JMX exposes no equivalent). New tiles/charts for threads and CPU, a
    GC collectors table, and a deadlock warning. A green **JMX** / yellow
    **jcmd** badge shows which plane is driving; if the bridge can't attach the
    panel falls back to the original jcmd-only polling.
  - **New MBean Browser** (`Java X: Browse MBeans…`, or the 🌳 icon on a running
    app's row): a JConsole-style domain → type → bean tree with a live filter,
    a refreshable attribute table (CompositeData rendered as JSON), and the
    MBean's operations — **invoking one goes through a confirm modal** and
    supports primitive/String arguments.
  - **Remote connect:** the browser's picker offers "Connect to a remote JMX
    URL…" (accepts `host:port` or a full `service:jmx:…` URL).
  - New pure utils with vitest (`jmx-protocol` line-framing / newest-JDK picker
    / jps parser, `object-name` tree builder — 20 tests); both webviews
    jsdom-verified. The bridge and the TS client were live-verified end-to-end
    against a running JDK-11 JVM (attach, read, mbeans, meta, subscribe ticks,
    and `invoke gc` dropping heap-used 12.5 MB→2.9 MB).

## 0.58.0 — 2026-08-01

- **JFR Viewer grows a full flame graph.** New Flame Graph tab: merged stacks
  as a canvas icicle (root at top), hover tooltip with samples + % of all /
  % of zoom, click-to-zoom into any frame with RESET ZOOM, and a highlight
  filter that grays non-matching frames. Under the hood the streaming
  ExecutionSample aggregator now builds a root-first stack TRIE (shared
  prefixes merge; ~O(distinct prefixes) memory) serialized with a node budget
  (min-count threshold doubles until ≤12k nodes), and the engine passes
  `--stack-depth 256` — **jfr print truncates stacks at 5 frames by default**,
  which would have gutted the graph. Colors are hash-stable warm hues; labels
  elide to fit. Verified on the CreditApp recording: 81 nodes, depth 46, the
  hottest path correctly showing slf4j/logback init under
  `BasicApplication.<clinit>`.

## 0.57.0 — 2026-08-01

- **JFR Viewer — render flight recordings without JMC.** Clicking any `.jfr`
  file (custom read-only editor) or `Java X: Open JFR Recording…` (newest-first
  picker over `.javax/jfr`) opens a webview report built with the JDK's own
  `jfr` CLI — the engine picks the NEWEST installed JDK's tool (newer readers
  open older recordings), so a JDK 11 recording renders via 21's `jfr`. Header
  tiles (duration / file / events / samples / GC pauses / peak heap) + tabs:
  **Overview** (event-type table with bars), **Hot Methods** (top frame per
  execution sample with % bars, samples by thread — `jdk.ExecutionSample` is
  STREAMED through an aggregator, never buffered whole), **GC & Heap** (canvas
  charts for heap used/committed + CPU load, GC pause list with causes),
  **Allocations & Errors** (allocation samples by class, error/exception
  aggregation, monitor blocking — with honest empty states when the recording's
  profile didn't capture them, e.g. no allocation events on JDK 11's default
  profile). Engine + parsers are vscode-free and unit-tested; live-verified
  against a real CreditApp recording. The Run Config JFR hint no longer points
  at JMC.

## 0.56.1 — 2026-08-01

- **Project Dashboard lists become tabs.** The side-by-side grid squeezed
  Gradle Tasks into a narrow column (midas: 8,027 tasks); Main Classes /
  Gradle Tasks / Test Classes are now full-width tabs (counts on the labels,
  green underline like the JAR Viewer). Each tab keeps its own filter and
  scroll position across switches; list height grows to ~54vh.

## 0.56.0 — 2026-08-01

- **Project Dashboard panel — clicking a Projects row now opens a dashboard
  instead of settings.gradle.** One place per repo: status badges
  (INSTALLED / CONNECTED · LS / INSTALLING·QUEUED) with Install (flips to
  Cancel while running), Connect/Disconnect, and Delete (the existing
  clean-project confirm) actions; stat tiles (modules / main classes / gradle
  tasks / test classes); three filterable, runnable lists — main classes
  (jdt.ls-resolved, Run / Config / Src per row), gradle tasks (from the
  Install-written index, grouped by group·module, Run per row), and test
  classes (convention scan, Run / Debug / Src); and a live **INSTALL OUTPUT
  console** streaming the Gradle log line-by-line (autoscroll, done/failed
  markers) via new `BootstrapService.onDidOutput`/`onDidStart` events. Badges
  and lists refresh themselves on install finish and connect/disconnect.
  settings.gradle stays one click away in the dashboard header. New command
  `javaX.openProjectDashboard` (also in the palette with a project picker).

## 0.55.0 — 2026-08-01

- **JAR Viewer redesigned — modern console with a three-tab class pane.**
  Header now carries stat tiles (size / classes / resources / used-by with a
  hover listing every project) + Reveal in Finder. The sidebar is a filterable
  class list with package headers and c/n chips (nested classes marked amber),
  live matched/total count in the filter box, and a green-bordered selection.
  The class pane splits into tabs: **Source** (editor-style card with traffic
  dots, filename, `UTF-8 · N lines`, a line-number gutter and the existing
  syntax highlighting — javap text when no sources JAR), **Members** (NEW —
  structured FIELDS/METHODS parsed from `javap -p -constants`: name, simplified
  types, constant values, right-aligned modifiers; count shown on the tab), and
  **Javadoc** (NEW — class description + annotation/heritage chips and METHOD
  DETAIL cards with `@param`/`@return`, parsed from the real source; `{@code}`/
  `{@link}` render as inline code). Plus COPY FQN, and the FQCN header with the
  package dimmed. New parsers `utils/javap-members.ts` + `utils/javadoc-parse.ts`
  are unit-tested; javadoc segments are structured data built into the DOM with
  `textContent` — never parsed as HTML.

## 0.54.0 — 2026-08-01

- **Run Config panel redesigned — modern two-column console.** Header row with
  the class name, an auto-detected SPRING BOOT / JAVA badge, a mono
  FQCN · repo · module breadcrumb, and prominent RUN (amber) / DEBUG
  (outlined) actions. Left column: launch-configuration cards — Java runtime
  with a DEFAULT chip on the JDK dropdown, environment variables in a
  line-numbered mini editor, JVM/program argument fields, and the JFR
  recording as a proper toggle switch. Right column: REPRODUCIBLE COMMANDS
  with a SHELL-EQUIVALENT chip, the caveats in an info callout, and the two
  phases as numbered step cards with COPY buttons and shell syntax
  highlighting (env assignments, flags, quoted strings, gradle task path,
  line continuations). All colors derive from theme tokens, so light themes
  stay legible; message protocol and saved-config shape are unchanged.

## 0.53.0 — 2026-08-01

- **JAR Viewer class pane goes full-fidelity.** Clicking a class now renders
  the REAL source — javadoc comments, parameter names, bodies — whenever a
  `-sources.jar` was bootstrapped (most CFG deps have one), falling back to
  raw `javap -p -constants` (full declaration with extends/implements, every
  member incl. private, constant values) instead of the previous bare
  public-member list. Both are syntax-highlighted (javadoc/comments, strings,
  annotations, keywords, numbers — theme chart colors, light+dark) and the
  pane header names which rendering you're looking at. Source pane widened;
  per-class results cached.

## 0.52.0 — 2026-08-01

- **JAR Viewer panel.** Clicking a JAR — in the JARs view or in a module's
  Dependencies section — now opens a dedicated panel rendering the whole JAR:
  header facts (size, class/resource counts, which projects use it via how
  many modules), a filterable package → class listing, and a member pane
  (javap, cached per class) with "Open source / API view" jumping to the real
  sources when a -sources.jar was bootstrapped. One panel per JAR. "Reveal in
  Finder" (the old click action) moved to the row's right-click menu and a
  button in the panel.

## 0.51.1 — 2026-08-01

- **Fix doubled view headers** like "JAVA X GRADLE TASKS: JAVA X - GRADLE
  TASKS". VS Code prefixes a view's `contextualTitle` when the view sits in
  its own location and only collapses the label when the two strings match —
  every view's contextualTitle now equals its name, so headers render once.

## 0.51.0 — 2026-08-01

- **Fix: JARs view crashed with "s is not iterable".** Since 0.47, Install
  also writes `index/<repo>.tasks.json` (the Gradle task maps) into the same
  directory as the jar indexes; the JARs view read them as jar indexes and
  crashed iterating their `{dir, tasks}` module values. Task maps are now
  excluded and every index's shape is validated before use.
- **Consistent view names**: Java X - Projects / Profiles / JARs / Runtime,
  and Java X - Main Classes / Test Classes / Gradle Tasks / Class Inspector.
- **Java Projects tree adopts the explorer's colors** (orange repo packages,
  blue module icons) so both project surfaces read as one family.
- **Class Inspector moved to its own "Java X" container** — drag that
  container to the Secondary Side Bar (right) once and VS Code keeps it
  there: a dedicated right-hand Java X dock you can drop more views onto
  (extensions cannot place containers there programmatically).

## 0.50.0 — 2026-08-01

- **JFR flight recordings on runs.** New "Record JFR flight recording"
  checkbox in the Run Config panel arms `-XX:StartFlightRecording` on the app
  JVM; the recording is dumped to `.javax/jfr/<class>-<timestamp>.jfr` on
  exit, with an "Open in JMC" notification. New command **"Java X: Open JFR
  Recording in JMC…"** picks from past recordings; JMC itself is an Eclipse
  RCP app that can't be embedded, so it launches externally (`javaX.jmcPath`,
  else `open -a "JDK Mission Control"` on macOS, else `jmc` from PATH).
- **JVM Inspector.** Running app rows gained an inline 📈 action opening a
  live class/memory panel: heap used/committed and loaded-class-count charts
  over time plus a top-classes-by-bytes table with Δ-instances per sample
  (leak hunting). Fed by polling `jcmd <pid> GC.heap_info` (2.5 s) and
  `GC.class_histogram` (10 s — it walks the heap at a safepoint); java-x
  spawns the app JVMs, so the pid is known. Polling stops when the JVM exits;
  the collected history stays on screen. Works for run AND debug sessions
  (jcmd only needs a same-user local process).

## 0.49.0 — 2026-08-01

- **Run Config panel.** Clicking a Main Classes row now opens a per-class Run
  Configuration panel instead of the source file (the source moved to the
  row's right-click menu and a link inside the panel). The panel shows the
  EXACT reproducible two-phase commands java-x runs — phase 1
  `gradlew :module:javaxRunSpec` including the mTLS sysprops, phase 2 the app
  JVM with `-cp "$(cat <spec>)"` so the pair is shell-equivalent — each with
  a Copy button, plus editable environment variables, JVM arguments, program
  arguments, and a Java-runtime picker (app JVM only; the build keeps the
  gradle JDK). Run/Debug buttons launch through the normal machinery.
- **Launch config is persisted per main class** at
  `.javax/launch/<fqcn>.json` (shareable, hand-editable; auto-saved as you
  type) and applies wherever the class is launched — the panel, the tree's
  inline ▶/🐞, and the editor CodeLens all honor it. `GradleRunner` gained
  `LaunchOverrides {env, jvmArgs, args, javaHome}`: env reaches both phases,
  JVM/program args and the JDK shape the phase-2 app JVM.

## 0.48.0 — 2026-08-01

- **jdt.ls transparency log: `.javax/logs/jdtls-<date>.log`.** The extension
  now spawns jdt.ls itself (LanguageClient `serverOptions` switched from an
  Executable to a StreamInfo function) and tees the wire into a date-rotated
  log: one summary line per LSP message in both directions
  (`--> request #12 textDocument/completion (1.2 KB)` /
  `<-- response #12 textDocument/completion OK (2.3 MB, 145 ms)` — responses
  are correlated to their requests with elapsed time), the server's stderr
  verbatim, and a live tail-follow of the Eclipse workspace log
  (`.metadata/.log`) where build/index errors land. Big payloads are never
  buffered — only a small prefix is read for the summary.
- **`javaX.languageServer.traceFrames`** (default off) writes FULL LSP
  payloads instead of summaries, for chasing a specific exchange — on large
  projects a single completion payload runs to megabytes, so leave it off
  otherwise. Restart the language server to apply.
- **New command: "Java X: Open jdt.ls Log (today)"** opens the current log
  file. Stopping the language server also now force-kills a wedged jdt.ls JVM
  that ignores the LSP shutdown handshake (previously it lingered until the
  next start's stale-server sweep).

## 0.47.0 — 2026-08-01

- **Gradle Tasks view.** Install now also maps every Gradle task the repo
  registers (per module, with group + description) into
  `index/<repo>.tasks.json`, and a new "Gradle Tasks" view in the Run & Debug
  container lists them repo → module → group → task with live filter. ▶ runs
  the task in its own Pseudoterminal (same formation as app runs — any number
  side by side, mTLS + JAVA_HOME injected, row in Running with ■). Repos
  installed before 0.47 need one re-Install to be mapped (verified live on
  vayu: 23 modules, incl. the remapped `:metricexporter` projectDir).
- **Dependencies section per module** in Connected Java Projects: each module
  now carries a purple "Dependencies (N JARs)" node listing the exact
  external JARs it resolved at the last Install — the transparency link from
  build.gradle version variables to the real files; click a JAR to reveal it
  in `.javax/libs`. Module dir → gradle path uses the new task index (exact,
  handles settings.gradle projectDir remaps), falling back to path-guessing
  for pre-0.47 indexes.
- **Gradle/JDK hardening.** `javax.run.gradle` now reaches sourceSets via the
  extension container (the `p.sourceSets` convention route is deprecated in
  Gradle 8, removed in 9). Install warns up front when the configured Gradle
  JDK is too new for the repo's Gradle (e.g. JDK 21 vs frodo's Gradle 5.4,
  which crashes cryptically past JDK 12) — official compatibility matrix in
  `utils/gradle-compat.ts`.

## 0.46.1 — 2026-08-01

- **Fix: Install exits 1 on configuration-cache repos (vayu).** vayu runs
  Gradle 8.13 with `org.gradle.configuration-cache=true` — the javax init
  script works on Project objects at execution time, which the config cache
  forbids, so the build FAILED (exit 1) even though the bootstrap task had
  fully succeeded (the index was written; the log tail showed only
  "Configuration cache entry discarded with 1 problem"). Every javax Gradle
  invocation (install, run spec, tests) now passes
  `-Dorg.gradle.configuration-cache=false`: a command-line system property
  overrides gradle.properties, and Gradles too old to know the option
  (5.4/6.9 CFG repos) just ignore it — `--no-configuration-cache` would be
  an unknown-flag error there. Verified live against vayu: BUILD SUCCESSFUL,
  23 modules, 1552 JARs indexed.

## 0.46.0 — 2026-08-01

- **Implementation hints: Cmd+click restored (italic dropped — user's
  pick).** VS Code's API forces a choice: inlay hints take Cmd+click but
  can't render italics; decorations render italics but can't take clicks.
  Asked, and direct navigation won. The hint is back to the inlay renderer
  with the 0.45.0 wording kept — gray "implementation found:
  CollateralSurveyControllerImpl", Cmd+click the name to jump, Cmd+hover to
  preview, "+N more" peeks the full list. The 0.45.1 warm-up lessons carry
  over: empty computes aren't cached and the ~10s projects poll re-pulls
  them, so hints still self-heal after a reload while jdt.ls indexes.

## 0.45.1 — 2026-08-01

- **Fix: implementation hints never appearing after a reload.** 0.45.0
  cached the computed hints per document version — a computation that ran
  while jdt.ls was still starting/indexing cached an EMPTY result, and since
  browsing never changes the document version, the hint stayed invisible
  forever (the 0.44.0 inlay variant was immune only because VS Code itself
  kept re-requesting). Empty results are no longer cached, the ~10s projects
  poll doubles as a warm-up heartbeat (hints appear shortly after indexing
  finishes, no edit needed), editor-switch triggers were added, and
  decorations now paint every editor showing the document (TextEditor
  identities churn across focus changes). Successful computes are logged to
  the Java X channel ("impl-hints: Foo.java → 1 hint(s)…") for
  diagnosability.

## 0.45.0 — 2026-08-01

- **Implementation hints restyled: italic + wording** (user feedback on
  0.44.0). The hint now reads *implementation found:
  CollateralSurveyControllerImpl* in italic gray. VS Code's inlay-hint API
  can't render italics, so the rendering switched to editor decorations
  (the GitLens inline-blame mechanism). Navigation moved accordingly:
  hover the italic text for a list of clickable implementation links
  (Cmd+click on the text itself no longer applies; Cmd+F12 on the interface
  name still works). Still capped at three names + "+N more"; hover lists
  up to 15.

## 0.44.0 — 2026-08-01

- **Inline implementation hints (IntelliJ code-vision style).** Interface
  names now carry a grayed `⇢ CollateralSurveyControllerImpl` inlay right
  beside them while browsing — no clicking a lens needed. Cmd+click a name
  to jump to that implementation (hover previews it); more than three
  implementations collapse to `+N more`, which peeks the full list. Powered
  by the same jdt.ls hierarchy query as Go to Implementations; hints appear
  once the LS is up and refresh as repos connect. (Respects the editor-wide
  `editor.inlayHints.enabled` setting.)

## 0.43.0 — 2026-08-01

- **Clickable "N references / N implementations" lenses fixed.** jdt.ls's
  gutter CodeLenses invoke client-side `java.show.references` /
  `java.show.implementations` commands that redhat.java used to register —
  Java X never did, so every click errored "command not found". Both are now
  registered and open VS Code's peek widget on the lens locations
  (IntelliJ-style: see all implementations of an interface without leaving
  the file).
- **Inline debug controls on Running rows.** A debug session row in the
  Main Classes view now carries the transport controls directly: while
  running it shows ⏸ pause + ■ stop; when paused (breakpoint/step) it swaps
  to ▶ continue, step over, step into, step out + ■ — no more hunting for
  the floating debug toolbar. Paused rows turn yellow and show the stop
  reason ("paused — breakpoint"). State comes from a DebugAdapterTracker on
  the DAP stream; controls talk to THAT session via customRequest, so
  concurrent sessions are each driven independently.
- **"Java X" editor menu moved next to the DevX commands** (top navigation
  group of the right-click menu, was buried below Source Action…).



- **Run tests at any scope.** ▶ now also sits on module rows (whole module:
  `:module:cleanTest :module:test`, no filter) and the repo row (every
  module: unqualified `cleanTest test`); 🐞 on modules too (the repo row is
  run-only — sequential test JVMs each suspending on the fixed 5005 would be
  a trap). Terminal titles show the scope: "Test authentication-impl",
  "Test midas".

## 0.42.0 — 2026-07-31

- **Test runner.** Test Classes rows got inline ▶ / 🐞: one dedicated
  terminal per launch (same Pseudoterminal machinery as app runs, beaker
  icon) driving `gradlew :module:cleanTest :module:test --tests <class>` with
  the nexus mTLS keystore injected — `cleanTest` because Gradle otherwise
  marks unchanged tests UP-TO-DATE and silently runs nothing. The row shows
  in the Running section as "building" until Gradle reaches the `:test` task,
  then "running"; green **TESTS PASSED** / red **TESTS FAILED** verdict plus
  the HTML report path at the end. Debug uses Gradle's `--debug-jvm`: the
  test JVM suspends on the FIXED port 5005 (per-run ports need Gradle ≥5.6;
  CFG still runs 5.4), Java X attaches when it opens (up to 5 min — compile
  comes first) and refuses to start a second debug test while 5005 is busy.
  Test runs don't take the per-repo build slot: the test task holds its
  daemon for the whole run, and Gradle's own locking covers concurrent
  builds.
- **Both Run & Debug trees now group by module** (project → module → class),
  matching the Connected Java Projects structure. Main Classes derives the
  module from each class's file path; Test Classes from the test root.
  Single-module repos stay flat, no extra level.

## 0.41.0 — 2026-07-31

- **New: Test Classes view** in the Java X Run & Debug container, below Main
  Classes — every conventional test class of the connected repos (green
  beaker rows), grouped by repo, package shown alongside, click opens the
  file. Has its own live filter (class / package / module / repo) and
  refresh. Discovery is by convention — `.java` files under any module's
  `src/test/java` named `*Test` / `*Tests` / `*IT` / `*TestCase` / `Test*` —
  because the bundled jdt.ls carries no test plugin (that's redhat's separate
  Test Runner); results are cached per repo until refresh or a
  connected-set change. Listing only for now: a ▶ that drives
  `gradlew :module:test --tests <class>` through the existing runner is the
  natural next step.

## 0.40.0 — 2026-07-31

- **Run & Debug view matches the colorful treatment:** Running header pulse
  and run terminals green, builds-in-flight yellow, debug (apps + sessions)
  orange, project rows orange packages, main classes in the Outline's class
  orange — states are now tell-apart-at-a-glance like Connected Java
  Projects.

## 0.39.0 — 2026-07-31

- **IntelliJ-style folder semantics in the Connected Java Projects folders
  mode:**
  - **Source roots are tinted and labeled** — `src/main/java` blue
    ("sources"), `src/test/java` green ("test sources"), `src/generated/java`
    purple ("generated sources"), `resources` dirs gold.
  - **Module folders are marked** — any folder holding a `build.gradle`
    (`.kts` too) gets the blue module icon and a "module" badge, so module
    boundaries jump out while scrolling a repo. (VS Code tree items can't
    render bold labels — the icon + badge is the equivalent signal.)
- **Packages got the classic Java package icon** (tan parcel,
  `media/java-package.svg`) instead of the `{}` namespace codicon.

## 0.38.0 — 2026-07-31

- **Class Inspector went colorful** — member icons now use the same theme
  colors as VS Code's Outline: orange classes, blue interfaces/fields, purple
  methods/constructors; Lombok-generated members glow gold (✨ +
  `charts.yellow`). Applies to type rows too.
- **Connected Java Projects: filter + collapse-all + view switch.**
  - **Filter** (funnel icon): live-filters packages by dotted name *and*
    classes by name — a package stays visible when any of its classes match,
    and then shows only the matching classes.
  - **Collapse All** — the standard tree button.
  - **View as Folders / View as Packages** toggle (IntelliJ's Project ↔
    Packages switch): folders mode shows the connected repo's plain file
    tree — rendered through `resourceUri`, so the file-icon theme and git
    decorations apply — for the times you do want `src/main/java`, gradle
    files, or resources. The title button flips with the mode; packages mode
    stays the default. Explorer rows got theme colors as well (orange
    project, blue module, namespace-colored packages, class-colored classes).

## 0.37.0 — 2026-07-31

- **The package browser moved to its own activity-bar container: "Java X
  Projects" → Connected Java Projects.** 0.36.0 put packages under every repo
  in the Java Projects tree — but that tree is the *management* surface (all
  ~25 discovered repos, mostly unconnected), so browsing drowned in noise.
  The new dedicated view (like Run & Debug's Main Classes) lists **only
  connected repos**: project → module → package → class; modules without Java
  sources are hidden. Java Projects itself is back to project → module
  (install/connect). An empty state links you to Java Projects to connect a
  repo.
- **Standard Java project operations on right-click** in the new view:
  - package / module → **New Class…** (inline + on the package's main source
    dir, with the Lombok templates) and **New Package…** (dotted-name input
    pre-filled with the parent package; created under `src/main/java`, then
    offers to create the first class). Freshly created empty packages stay
    visible — empty *leaf* dirs count as packages now (empty middles still
    don't).
  - package → **Copy Package Name**, **Reveal in Finder**.
  - class → **Reveal in Finder**, **Delete Class…** (modal confirm, moves to
    trash).

## 0.36.0 — 2026-07-31

- **Package-native project browsing** in the Java Projects tree — modules now
  expand IntelliJ-style: **project → module → package → class**. Packages are
  flattened dotted names (`com.indodana.credit`) merged across the module's
  source roots, so `src/main/java` / `src/test/java` / `src/generated/java`
  never appear as tree levels. Packages/classes living outside main sources
  carry a `test` / `generated` badge; class rows open the file on click.
  Packages are computed lazily per module expansion (nothing is scanned until
  you open a module), and only directories directly containing `.java` files
  become package rows (no empty `com` / `com.indodana` middles).

## 0.35.0 — 2026-07-31

- **New: Class Inspector view** (Java X sidebar) — IntelliJ-structure-style
  inspection of the active editor's class: constructors / fields / methods
  with real visibility modifiers, merged with the compiled `.class` (`javap
  -p` against the module's output dir in the central Eclipse layout). Members
  that exist in bytecode but not in source — Lombok's getters / setters /
  constructors / `builder()`, enum `values()`/`valueOf` — show a ✨ icon and a
  "generated" badge, so what Lombok actually produced is visible at a glance.
  Source rows jump to the declaration on click. Refreshes on editor switch
  and on save (the Eclipse builder recompiles on save). When the type has no
  compiled `.class` yet, the type row says "not compiled" instead of
  pretending there are no generated members.
- **New: editor right-click → "Java X" submenu** with Lombok-first generation:
  - **Add Constructor…** — `@RequiredArgsConstructor` / `@AllArgsConstructor`
    / `@NoArgsConstructor` insert the annotation + `import lombok.*` line as a
    pure text edit (works even while the language server is cold; detects an
    annotation that is already present), or **Explicit constructor…** which
    drives jdt.ls's own generate-constructors protocol
    (`java/checkConstructorsStatus` → field multi-pick + super-constructor
    pick when there are several → `java/generateConstructors` WorkspaceEdit)
    — the same engine redhat.java's "Generate constructors" uses, now
    first-party.
  - **New Java Class…** (also on explorer folder right-click) — package
    auto-derived from the `src/{main,test,generated}/java` root; templates:
    plain class / interface / enum / record, plus Lombok `@Data
    @NoArgsConstructor @AllArgsConstructor` (mutable DTO) and `@Value
    @Builder` (immutable value object).

## 0.34.0 — 2026-07-22

- **New: "Java X: Run Diagnostics"** (command palette, and the pulse icon in
  the Runtime view title bar) — produces one plain-text health report you can
  copy-paste when a setup misbehaves on another machine. It covers:
  - environment: Java X / VS Code / OS versions, `JAVA_HOME`, `openssl` version;
  - JDKs discovered, which one runs the language server (flags JDK 24+ as a
    risk for the bundled jdt.ls) and which one Gradle uses;
  - the pkictl cert (source, subject, expiry — flags expired/missing);
  - language-server status and its data dir;
  - a scan of jdt.ls's own log for build-path errors, corrupt-jar
    (ZipException) errors, and the count of "cannot be resolved" markers;
  - per connected repo: source-folder count (and whether `src/generated`
    was found), plus **a pool integrity check listing any MISSING or CORRUPT
    jars** — the usual root cause of "the project cannot be built" and dead
    navigation;
  - a short "likely issues" verdict.
  The report is written both to the Java X output channel and to a temp file
  (with an "Open report file" button).

## 0.33.1 — 2026-07-22

- **Generated sources (`src/generated/java`) are now on the classpath.** CFG
  repos commit jOOQ/codegen output there — in midas that's 6 modules
  (`com.indodana.*.jooq.*` and the generated `*Enum` types). The flat
  classpath only collected `src/{main,test}`, so those imports never
  resolved and jdt.ls flooded the affected modules with "cannot be resolved
  to a type" / "import … cannot be resolved" (e.g. `com.indodana.credit.jooq`,
  `InstallmentRequestTypeEnum`, `NamespaceEnum`). `src/generated/{java,resources}`
  is now recognised as a source scope with its own output dir.
  **Reconnect the repo (or regenerate the flat classpath) and restart the
  Java X LS to pick it up.** `build/generated*` (uncommitted) stays excluded.

## 0.33.0 — 2026-07-22

- **One dedicated terminal per launch, opened the instant you click Run, and
  showing build → run in sequence.** Previously the build ran in a single
  shared task terminal and the run in a separate one, and a launch produced
  no feedback until its build had finished — so you effectively had to wait
  for one class to reach "running" before launching the next. Now every
  click immediately opens that class's own terminal, which shows
  `Waiting…` / `Building …` / `Running …` in place. Launch DebitApp,
  MidasApp and CreditApp back to back and you get three terminals right
  away, each carrying its own build then run.
- Builds are still serialized per repo (so several launches from one repo
  don't spin up multiple 3–4 GB Gradle daemons at once) — but a queued
  launch now says so in its own terminal instead of appearing to hang. Runs
  never block subsequent builds.
- The Run view's **Running** row shows each launch's phase live — a
  "building…" state with a wrench icon, flipping to run/debug once the JVM
  is up — and ■ cancels the build or stops the app accordingly.
- Internally this retires the VS Code Task API for runs entirely (build and
  run are both spawned into a `Pseudoterminal` the extension owns), removing
  the last of the task-terminal-reuse behaviour that caused the earlier
  "shared terminal" bugs.

## 0.32.1 — 2026-07-22

- **Fixed the real cause of "sometimes one terminal, sometimes many": the
  run build was failing on nexus mTLS.** Phase 1 (`:javaxRunSpec`, which
  compiles the module and so resolves its compile classpath) never passed
  the pkictl client certificate — unlike Install. So any run whose
  dependencies needed a nexus round-trip (typically a SNAPSHOT metadata
  refresh) got bounced to the Vouch login and failed with "405 Method Not
  Allowed", and a failed build means `spawnJvm` never runs and no dedicated
  terminal appears. Whether the Gradle cache was warm decided success, which
  looked random. Phase 1 now builds and passes the mTLS keystore exactly
  like Install does, using a throwaway per-build keystore file (deleted
  afterward) so concurrent runs across repos can't clobber each other's.
- **Added run/build logging to the Java X output channel** (Java X: Show
  Java X Log): each launch logs the path taken (Gradle two-phase vs. the jdt
  fallback), whether the mTLS keystore was injected, the build's exit code
  and whether a classpath came back, and each spawn ("… in its OWN new
  terminal") with the live-run count — so any remaining flakiness is
  diagnosable from the log.
- Build failures now hint at the mTLS/pkictl cert as a likely cause.

## 0.32.0 — 2026-07-22

- **Each Run/Debug now genuinely gets its own terminal.** Run three apps
  (DebitApp, MidasApp, CreditApp) and you get three separate terminals that
  run side by side. The run phase no longer goes through VS Code's Task API
  at all — three tries at coercing its terminal-reuse semantics
  (`panel: New`, per-instance task identity, per-execution nonces) all still
  collapsed runs into one terminal. Instead the JVM is now spawned into a
  `Pseudoterminal` the extension owns directly: `createTerminal` always
  creates a fresh terminal, so separation is guaranteed with no reliance on
  task identity. The terminal still stays open after the process exits
  (showing the exit code) so failures remain readable — the reason runs were
  put on the Task API in the first place.
- The Run view's **Running** section now tracks these app runs directly
  (■ stops the JVM and closes its terminal, click reveals it); the
  short-lived Gradle build step still appears briefly, now labelled
  "building". Rerunning a class whose previous run already exited reuses its
  (now idle) terminal; concurrent runs of the same class keep the "(2)"
  suffix so their terminals stay distinct.

## 0.31.2 — 2026-07-22

- **Every Run/Debug now spawns its own fresh terminal — no reuse paths
  left.** 0.31.1's per-instance definition key still shared a terminal in
  live testing, so the launcher now forces separation three ways: the task
  panel kind is `New` (VS Code's explicit "always create a new terminal"),
  the `instance` definition property carries a per-execution nonce (two
  launches are never the same task, so a second run can't be swallowed as
  "already active"), and when a title is relaunched after exit its old
  terminal is closed first (rerun replaces its output, IntelliJ-style), so
  fresh-terminal-per-run doesn't accumulate dead terminals.

## 0.31.1 — 2026-07-22

- **Concurrent instances now get their own terminals.** 0.31.0 gave each
  instance a unique task *name*, but VS Code keys task identity — and which
  dedicated terminal an execution reuses — off the task *definition*, and
  every launch shared the bare `{ type: "javax-run" }`, so "Run App" and
  "Run App (2)" still landed in one terminal. The definition now carries an
  `instance` property (declared in `taskDefinitions`, set to the task name),
  making every launch a distinct task with its own dedicated terminal;
  rerun-after-exit keeps the same instance key, so it still recycles its old
  terminal instead of piling up new ones.

## 0.31.0 — 2026-07-22

- **mTLS keystore now works on every laptop** — fixes Install failing with
  "keystore password was incorrect" on machines where Homebrew OpenSSL 3 is
  first on PATH. The password was never wrong: OpenSSL 3's default PKCS12
  algorithms (AES-256/PBKDF2/SHA-256-MAC) are unreadable by JDK 8 <8u301 and
  11 <11.0.12, which report the parse failure as a bad password. The export
  now pins legacy algorithms (`PBE-SHA1-3DES` + SHA-1 MAC) — produced
  identically by LibreSSL (stock macOS) and OpenSSL 3, readable by every
  JDK — so the keystore no longer depends on which `openssl` the machine
  resolves.
- **The same main class can now run multiple times concurrently.** VS Code
  keys task executions (and their dedicated terminals) by task name, so
  rerunning used to terminate the previous instance. Each new instance of an
  already-running class now takes the lowest free suffix — `Run App`,
  `Run App (2)`, … — with its own terminal, stop button, and (for Debug) its
  own matching debug session name. Reruns after exit still reuse the base
  name and its terminal, so nothing piles up.

## 0.30.1 — 2026-07-20

- The Main Classes view is back in the **left activity bar** (0.30.0 briefly
  defaulted it into the bottom panel — the intent was for the *run output*
  to live in the bottom panel, which task terminals already do via the
  TERMINAL view; the navigation tree stays in the sidebar).

## 0.30.0 — 2026-07-20

- **Multiple apps can now run concurrently.** Root cause of the old limit: a
  long-running app inside a Gradle `JavaExec` task holds the repo's Gradle
  execution locks for its entire lifetime, blocking every other build (a
  second app, an Install) on that repo. Run/Debug is now two-phase:
  1. *Build* (Gradle, short-lived, serialized per repo): `:javaxRunSpec`
     compiles the module per the repo's own build spec and emits its runtime
     classpath — then releases all locks.
  2. *Run* (Java X): the JVM is spawned directly from that classpath
     (`java @argfile MainClass`, project JDK), one dedicated terminal per
     app. Debug adds a suspended JDWP agent and attaches — usually within a
     second now, since compilation already happened in phase 1.
  Rerunning the same class still replaces its previous run; different
  classes run side by side.
- **The Java X Run view moved to the bottom panel** — it now sits as a tab
  next to PROBLEMS / OUTPUT / DEBUG CONSOLE / PORTS instead of the side bar
  (drag it back anywhere you like; this is just the default home).

## 0.29.0 — 2026-07-20

- **Main Classes view: filter + collapse-all + a Running section.**
  - Live filter (funnel icon, same behavior as the Java Projects filter):
    matches class name, package/FQN, or repo name; active filter shown in
    the view description.
  - Standard collapse-all button.
  - A **Running** section appears at the top whenever something is active:
    Gradle run tasks (click shows the terminal, ■ stops the process) and
    `javax-java` debug sessions (■ disconnects). Rows update live on task
    and debug session start/end.

## 0.28.0 — 2026-07-20

- **Run/Debug terminal no longer vanishes on failure.** Gradle runs are now
  VS Code Tasks (`ProcessExecution` — still shell-isolated, same pinned
  JAVA_HOME): the task terminal stays open after the process exits, so build
  and runtime errors remain readable, with the exit code shown. Rerunning a
  class terminates its previous run's task.
- **Debug waits fail fast**: if Gradle exits before the suspended JVM comes
  up (compile failure), the attach wait stops immediately with a pointer to
  the terminal — no more 5-minute timeout.
- **`.class` editors are Java now**: syntax highlighting for class-file
  contents (attached sources / decompiled) opened from navigation or debug
  stack frames, and the language client also serves `jdt://` documents — so
  those editors get hover, ctrl+click and references like regular files.

## 0.27.1 — 2026-07-20

- **Gradle runs are now shell-isolated.** The run/debug terminal spawns
  gradlew DIRECTLY as the terminal process instead of typing a command into
  your shell — zshrc/sdkman/aliases never execute, so the environment is
  deterministic. `JAVA_HOME` is pinned to the same Gradle JDK the Install
  flow resolves (`javaX.javaHome` → `java.import.gradle.java.home` → env).
  Fixes the first live run failing with `Unrecognized VM option
  'MaxPermSize=2048m'`: the shell's default JDK was 21, and midas's
  `gradle.properties` daemon args are JDK-8-era.

## 0.27.0 — 2026-07-20

- **Run/Debug is now a build-tool orchestrator (default).** Pressing ▶/🐞 on
  a main class runs it END-TO-END through the repo's own Gradle build: an
  injected `javaxRun` JavaExec task compiles the module per the project spec
  (codegen, resources, exact dependency configurations) and runs the class
  from the module's runtimeClasspath, in a terminal at the repo root. Gradle
  launcher resolution reuses the install machinery (wrapper / cached dist /
  CI-pinned version), including the 3G daemon-heap injection.
- **Debug**: the same Gradle run with a suspended JDWP agent on a free port;
  Java X waits for the JVM (progress notification, cancellable) and attaches
  via the `javax-java` debug type — breakpoints/stepping map to sources
  through the connected jdt.ls project.
- Division of labor is now explicit: **Install + Connect (jdt.ls) = code
  navigation; Run/Debug = the project's own build runtime.** The IDE-classpath
  launcher remains available via `"javaX.launcher": "jdt"` (or launch.json
  `javax-java` launch configs); Maven repos would slot into the same seam
  when needed.

## 0.26.1 — 2026-07-20

- **Dependency health is now checked where you need it.** Java X knows every
  jar a repo needs (its `.javax` index), so it now validates the pool
  (existence + zip magic) at two points and offers the one-click fix:
  - **Connect**: if the repo's index lists jars that are missing/broken in
    the pool, a warning names them and offers `Install <repo>`.
  - **Run/Debug**: launching a project with missing/broken pool jars is
    guaranteed to fail (the Eclipse builder aborts the whole project → no
    classes → ClassNotFoundException), so the launch stops with an
    explanatory error + `Install <repo>` button instead.
- This turns the cryptic "Project 'X' is missing required library …" +
  "cannot be built until build path errors are resolved" markers into an
  actionable flow.

## 0.26.0 — 2026-07-20

- **Build before launch.** Run/Debug now triggers an incremental workspace
  compile (`vscode.java.buildWorkspace`) and waits for it (progress
  notification) before starting the JVM — previously a broken or unfinished
  build surfaced as a bare `ClassNotFoundException` in the terminal. If the
  build fails or has errors you get a clear warning with Launch Anyway /
  Cancel. Opt out per config with `"buildBeforeLaunch": false`.
- Reminder that motivated this: a missing/invalid jar on the classpath makes
  the Eclipse builder abort the WHOLE project (zero classes emitted) — the
  new warning points at the Problems panel and re-Install instead of leaving
  a cryptic CNFE.

## 0.25.2 — 2026-07-19

- **Launch command line no longer floods the terminal.** Run/Debug inlined
  the whole flat classpath (~1000 jars, hundreds of KB) into `java -cp …`.
  New default `shortenCommandLine: "argfile"` makes the terminal show a
  short `java @/tmp/….argfile MainClass` instead (override per launch
  config: none/jarmanifest/argfile/auto).

## 0.25.1 — 2026-07-19

- **Fix: Main Classes view stuck "loading" forever + jdt.ls starved.** The
  view awaited `vscode.java.resolveMainClass` (a whole-workspace search that
  blocks behind a full reindex, e.g. after Clean & Restart) and re-issued it
  on every projects poll tick (~10s) with no in-flight dedupe — a search
  storm that also starved completion/IntelliSense. Now: exactly one search
  in flight, rows render immediately as "searching… (waits for indexing)"
  and fill in when the result lands; refreshes only happen when the
  connected set actually changes, the LS restarts, or you press refresh.
- **Poisoned-artifact defense in the install script.** Found in the wild: an
  expired vouch/SSO session makes nexus return its login HTML page with
  HTTP 200 — Gradle caches it AS the artifact (63 such files found and
  purged from the local cache tonight; one was midas's
  `outbound-latency-metric-commons-1.0.0.jar`, which broke jdt.ls indexing
  and resolution). Install now verifies the zip magic before pooling a jar
  (bad ones are recorded as failures in the index instead), copies via
  temp-file + atomic rename (no more torn jars from killed installs), and
  self-heals an already-torn/poisoned pool jar on the next install.

## 0.25.0 — 2026-07-19

- **Fix: compileOnly dependencies (lombok!) missing from the classpath.**
  The install script resolved only runtime-side configurations
  (`testRuntimeClasspath`/`runtimeClasspath`) — but `compileOnly` deps appear
  in NO runtime configuration, so repos like cermati-java-commons had no
  lombok jar at all ("The import lombok cannot be resolved" across the repo;
  midas/user-service only worked because other modules leaked lombok into
  runtime). Install now resolves the UNION with the compile side
  (`testCompileClasspath`/`compileClasspath` fallback), which brings lombok
  and other provided-style annotation jars. **Re-install + re-connect each
  repo to pick this up** (re-install is fast off warm caches).
- **New "Java X Run & Debug" activity-bar view (Main Classes)**: every
  connected repo, expanded to the classes with a `static void main` the
  debug plugin finds — inline ▶ Run / 🐞 Debug on each row, click opens the
  file, refresh in the view title. The list refreshes on LS start/stop,
  connect/disconnect, and each time the view becomes visible.
- This view is also the reliable alternative to the editor CodeLens: a Java
  file opened BEFORE its repo was connected gets claimed by jdt.ls's
  invisible project and `resolveMainMethod` fails on it ("Resource ... is
  not local") until the file is reopened. The tree works from the project
  model instead of open editors, so it doesn't hit this.

## 0.24.1 — 2026-07-19

- **Removed the orphaned redhat-era commands** that sat confusingly next to
  the real Java X ones: `Import Java Projects into Language Server`
  (`javaX.lsImportProjects`), `Restart Java Language Server`
  (`javaX.lsRestart`), `Clean Java Language Server Workspace`
  (`javaX.lsCleanWorkspace`) and the unlisted `javaX.importProjectToLs` —
  all of them drove redhat.java, which Java X replaced in 0.12+. The
  "importing…" status bar and service state that only they used went too.

## 0.24.0 — 2026-07-19

- **Runner & Debugger — run/debug a main class without redhat.java.** The
  Microsoft Java debug plugin (`com.microsoft.java.debug.plugin` 0.53.1, from
  Maven Central) is now bundled into our jdt.ls via
  `initializationOptions.bundles`; it runs a DAP server inside the language
  server. A thin `javax-java` debug client wires VS Code to it — no
  dependency on vscjava.vscode-java-debug or redhat.java.
- **Run | Debug CodeLens** above every `main()` in connected repos (resolved
  by the plugin, so lenses appear once the repo is connected and indexed).
- **F5 / launch.json**: `javax-java` launch configs resolve mainClass (picker
  when omitted), classpath (from the Java X flat model), the project's JDK,
  and cwd (the real repo root, not `.javax/eclipse/<repo>`). Defaults to the
  integrated terminal. Attach to a remote JVM (JDWP host/port) also supported.
- New commands: `Java X: Run Main Class`, `Java X: Debug Main Class` (palette
  → main-class picker). Java breakpoints enabled via the `breakpoints`
  contribution.
- Restart the Java X Language Server once after installing this version — the
  debug plugin loads at server startup.

## 0.23.0 — 2026-07-19

- **Profiles tree view**: dedicated "Profiles" section in the Java X sidebar.
  One row per profile (active one marked), expandable to its repos with
  live `connected ✓` / `not in workspace` state. Inline ▶ activates,
  right-click Activate/Edit/Delete, `+` title button saves a new profile,
  welcome content with a Save Profile button when empty.
- New commands: `Edit Profile (repos)`, `Delete Profile`. The layers button on
  the Java Projects title was removed (the view replaces it).
- Profile rows react to hand-edits of `javaX.profiles` in settings.json.

## 0.22.0 — 2026-07-19

- **Profiles**: named working sets of repos (`javaX.profiles` workspace
  setting — shareable via settings.json). `Java X: Activate Profile` does a
  full clean slate: disconnect + uninstall every connected repo, then
  install → connect each profile repo in order, with one LS restart at the
  end only if an incremental import missed. Progress notification for the
  profile steps; the install status bar carries the Gradle phase.
- `Java X: Save Profile` names a set (existing name overwrites) with the
  currently connected repos pre-selected.
- Install now reports a real outcome internally (`ok`/`failed`/`cancelled`/
  `queued`/`duplicate`) so orchestration only connects what installed.

## 0.21.0 — 2026-07-19

- **Bundled Lombok agent** (1.18.46) passed as `-javaagent` to jdt.ls. Lombok
  generates members inside the compiler — without the agent, every
  `@Getter`/`@Builder`/`@Slf4j` usage was "method undefined" (the bulk of a
  64K-error initial midas build). redhat.java used to provide this silently.
- **Test dependencies**: install now resolves `testRuntimeClasspath`
  (superset) with `runtimeClasspath` fallback, so test-only libraries
  (assertj, hamcrest, wiremock, spring-boot-starter-test) reach the classpath.
  Re-run Install on each repo to pick these up.

## 0.20.0 — 2026-07-19

- **Install queue**: installs are serialized FIFO — request as many as you
  like, they run one Gradle at a time. Queued rows keep their spinner and the
  inline cancel dequeues them; the status bar shows `· N queued`.
- Rationale: parallel runs raced on the fixed-path mTLS keystore (per-run
  random password) and could tear shared JARs copied concurrently into
  `.javax/libs`; each run also costs a 3–4 GB Gradle daemon.

## 0.19.0 — 2026-07-19

- **"Bootstrap" renamed to "Install"** everywhere user-facing (npm mental
  model: it resolves + fetches dependencies, never compiles). Command IDs
  unchanged.
- **New `Clean Project` command** (trash icon beside the plug): disconnects
  from the LS, deletes the central Eclipse project and the repo's `.javax`
  index, and uninstalls its JARs from the pool — keeping any JAR another
  repo's index still references. `-sources.jar` and API-index entries go with
  removed JARs.

## 0.18.0 — 2026-07-19

- **Live install status bar**: spinning item with the current Gradle phase and
  elapsed time — `configuring :x`, `downloading dependencies (N)`,
  `resolving :module (12/205)` (new per-module progress line printed by the
  injected init script). Click opens the Java X log. Elapsed time ticks even
  while Gradle is quiet.

## 0.17.1 — 2026-07-19

- **Fixed silently-broken incremental import** (affected 0.14–0.17.0):
  `java.project.changeImportedProjects` takes configuration *file* paths —
  passing a directory no-ops without error, leaving opened files in jdt.ls's
  classpath-less "invisible project" (symptom: annotations like
  `@SpringBootApplication` unresolved, no ctrl+click). Now sends
  `<projectDir>/.project` and polls `java.project.getAll` until the project
  actually appears (falls back to restart otherwise).

## 0.17.0 — 2026-07-19

- **Central Eclipse layout**: generated projects moved out of the repos into
  `<workspace>/.javax/eclipse/<repo>/`, reaching sources through an Eclipse
  linked folder named `repo`. Repos stay 100% pristine — no `.project`,
  `.classpath`, `.settings`, or `bin/` in `git status`; compiled outputs land
  in the central project dir.
- jdt.ls now has exactly one root (`.javax/eclipse`) — it never crawls the
  workspace repos; stray auto-imports are structurally impossible.
- Connect auto-migrates by deleting legacy repo-root files; Disconnect deletes
  the central project dir.

## 0.16.0 — 2026-07-19

- **New `Disconnect from Java X LS` command**: removes the project from the
  running server (no restart) and deletes the generated files — `.project`
  only when it carries the Java X marker, and only the output dirs the
  `.classpath` declares (never a blanket `bin/` delete). `.javax` install data
  kept, so reconnecting takes ~100 ms.

## 0.15.0 — 2026-07-19

- **Scoped jdt.ls roots**: the server is initialized with
  `initializationOptions.workspaceFolders` limited to connected repos instead
  of the whole multi-repo workspace — ending the ~130-repo crawl and the
  Buildship Gradle-probing of stray checkouts; strays are purged on startup.
  (Superseded by 0.17.0's single fixed root.)

## 0.14.0 – 0.14.3 — build correctness for the flat model

- Unique output folder per source folder (mirrored `src→bin`) — shared outputs
  crashed the JDT builder.
- Generated `.settings/org.eclipse.jdt.core.prefs` with
  `resourceCopyExclusionFilter=*` — resource-copy collisions
  (`ImageBuilderInternalException`) had been failing the whole midas build and
  degrading navigation across the repo (0.14.3, log-verified fixed).
- `javaX.serverHeap` setting; orphaned jdt.ls processes killed on start.

## 0.12.0 – 0.13.2 — the big pivot: bundled jdt.ls, redhat.java dropped

- **Bundled Eclipse jdt.ls** (~52 MB) launched directly with Gradle/Maven
  import forced off — it reads the flat `.project`/`.classpath` Java X
  generates instead of running any Buildship sync.
- **Flat classpath generator + "Connect to Java X LS"** (plug icon): Eclipse
  project files generated from the repo's own `.javax` index (exact per-repo
  JAR versions), incremental import into the running server.
- `jdt://` content provider (library navigation with attached sources),
  refs/impls CodeLens, `java.import.*` settings declared by Java X once
  redhat.java is disabled.
- **LS dashboard**: status, connected projects, workspace/symbol query,
  server-log tail.

## 0.8.0 – 0.11.0 — API index & redhat.java integration era

- **API index**: `javap -public` over the JAR pool (`.javax/api-index/`),
  class/method search, expandable class members in the JARs tree,
  `javaX.apiIndexWorkers` setting.
- Runtime view: JDK discovery (SDKMAN/system/Homebrew), per-repo Gradle
  wrapper versions, pkictl certificate status + configuration.
- redhat.java-era LS helpers (import project pickers, workspace inspection,
  known-vs-stray project listing) — later superseded by the bundled server.

## 0.2.0 – 0.7.0 — central `.javax` & bootstrap era

- **Bootstrap** (cloud icon): runs the repo's own `gradlew` with an injected
  init script to resolve every module's dependencies into a **central
  workspace `.javax`** — shared, deduplicated `libs/` pool (version conflicts
  become visible), `-sources.jar` resolution, per-repo `index/<repo>.json`.
- The company Nexus reached through the pkictl mTLS cert converted to a
  fresh PKCS12 keystore per run; Gradle wrapper fallbacks (committed jar →
  cached dist → CI-pinned version); daemon heap injected when the repo sets
  none.
- **JARs view** (version conflicts / per-project / all, classes inside JARs);
  quiet progress UX (row spinner + inline cancel, no toasts).

## 0.1.0 — initial release

- Java X activity bar with a **Java Projects tree**: scans every workspace
  folder for Gradle projects (`settings.gradle`), lazily expands each into its
  modules, click-through to build files, live filter.
