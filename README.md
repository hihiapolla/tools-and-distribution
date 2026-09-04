# tools-and-distribution

Public distribution point for CFG internal tooling. Each directory holds one tool's install
shim plus its published `VERSION`, `CHANGELOG.md` and `SHA256SUMS`; the binaries are attached
to GitHub Releases on this repo (tag `<tool>-v<version>`). Source stays in private repos.
Nothing here contains secrets — installs need no git access and no tokens.

| tool | one-liner | source |
|---|---|---|
| **localdevctl** — local dev environment (kind + Postgres + Vault + Loki/Grafana) | `curl -fsSL https://raw.githubusercontent.com/hihiapolla/tools-and-distribution/main/localdevctl/install.sh \| bash` | `hihiapolla/tollm` → `devops-x/`; releases `localdevctl-v*` |

Run the one-liner from inside the repository you want the tool injected into. Pin with
`LOCALDEV_VERSION=x.y.z`. Publishing: `devops-x/release.sh all` in tollm stages the metadata here;
then push and `gh release create localdevctl-v<version> …` with the tarballs.
