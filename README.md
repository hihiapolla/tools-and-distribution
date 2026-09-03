# tools-and-distribution

Public bootstrap scripts for CFG internal tooling. Each directory holds the *entry point*
for one tool; the tools themselves live in private repos and are fetched with your own git
access (ssh key). Nothing here contains secrets or tool code — only the install shim.

| tool | one-liner | source |
|---|---|---|
| **localdevctl** — local dev environment (kind + Postgres + Vault) | `curl -fsSL https://raw.githubusercontent.com/hihiapolla/tools-and-distribution/main/localdevctl/install.sh \| bash` | `hihiapolla/tollm` → `devops-x/` |

Run the one-liner from inside the repository you want the tool injected into.
