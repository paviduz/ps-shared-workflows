## Shared conventions (project-wide)

This section applies to every repo in the homelab-infra / context-engine /
personal-brain project cluster: homelab-infra, homelab-context,
personal-brain, homelab-tools, context-engine, knowledge-server. It's
generated from `ps-shared-workflows/defaults/AGENTS.shared.md` — edit it
there, not in a copy. Changes propagate to every repo automatically via
`agents-md-sync.yml`. See `AGENTS.local.md` in this repo for conventions
specific to it.

### Decisions

Record a decision doc under `homelab-infra/decisions/YYYY-MM-DD-title.md`
whenever you make a non-obvious architectural or process choice, in any repo
in this cluster, not just homelab-infra. State what was chosen, what
alternatives were rejected and why, and what's explicitly deferred. Read a
couple of existing docs there for the format before writing one.

### Repos are siblings, not vendored

Every repo in this cluster is assumed checked out as a sibling directory on
the same machine. Scripts that need another repo's content take a
`-XRepoPath`-style parameter defaulting to `../<repo-name>`. If a sibling is
missing, fix the path or ask the user to clone it — don't introduce a git
submodule or vendor a copy to work around it.

### Generated files are committed by CI, not by hand

Any file whose header says it's generated (context outputs, this file's own
`AGENTS.md`) is written by a CI job and committed with a `[skip ci]` commit.
Change its source and let CI regenerate it instead of editing it directly.

### Commit and PR conventions

- Commit subjects follow `type(scope): summary` (feat/fix/docs/refactor/chore/ci).
- Every repo in this cluster has "Automatically delete head branches" enabled
  in its GitHub settings — don't manually delete merged branches, and don't
  turn this setting off.

### PowerShell repos

If this repo contains PowerShell modules or scripts, they run through
`ps-shared-workflows`' `ps-quality-gate.yml` (PSScriptAnalyzer + Pester) in
CI. Fix the underlying finding rather than suppressing an analyzer rule or
adding `-ErrorAction SilentlyContinue` to make a failing check pass.

### Secrets

Never commit a secret value. `homelab-infra/secrets/README.md` inventories
secret names and where they live (never the values) — check there before
assuming a credential doesn't exist yet.
