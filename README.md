# ps-shared-workflows

Reusable GitHub Actions workflows for PowerShell code quality enforcement,
plus the canonical source for project-wide AGENTS.md conventions shared
across the homelab-infra / context-engine / personal-brain repo cluster.

## Workflows

### `dispatch-downstream.yml`

Sends a `repository_dispatch` event to another repo. Use this to chain
cross-repo CI workflows without polling or scheduled runs.

```yaml
jobs:
  notify:
    uses: paviduz/ps-shared-workflows/.github/workflows/dispatch-downstream.yml@main
    with:
      target_repo: homelab-context
      event_type: infra-changed
    secrets:
      HOMELAB_PAT: ${{ secrets.HOMELAB_PAT }}
```

| Input | Required | Description |
|-------|----------|-------------|
| `target_repo` | yes | Repository name without owner |
| `event_type` | yes | String the target listens for in `repository_dispatch.types` |

The `HOMELAB_PAT` secret must have `Contents: read and write` permission on
the target repo (fine-grained PAT) — that's what the `repository_dispatch`
endpoint actually requires, confirmed via the `x-accepted-github-permissions`
response header. If it's a fine-grained token, the target repo also needs to
be in the token's repository allowlist, or the API returns 404, not 403.

### `agents-md-sync.yml`

Regenerates a calling repo's `AGENTS.md` from `defaults/AGENTS.shared.md`
(this repo, the single source of shared conventions) plus the calling repo's
own `AGENTS.repo.md`, and commits it if it changed. Add to a repo:

```yaml
# .github/workflows/agents-md-sync.yml
name: Sync AGENTS.md

on:
  push:
    branches: [main]
    paths: ['AGENTS.repo.md']
  repository_dispatch:
    types: [shared-conventions-changed]
  workflow_dispatch:

jobs:
  agents-md:
    permissions:
      contents: write
    uses: paviduz/ps-shared-workflows/.github/workflows/agents-md-sync.yml@main
```

The caller must grant `contents: write` itself — a reusable workflow's
requested job permissions can't exceed what the calling job grants, and
without it this fails as an instant `startup_failure` with no jobs run
(nothing in the logs points at the real cause; found the hard way).

No secrets required beyond that — this repo is public. `notify-agents-md-change.yml`
(in this repo) dispatches `shared-conventions-changed` to every repo in the
cluster whenever `defaults/AGENTS.shared.md` changes, so each one
regenerates automatically. That dispatch needs a `HOMELAB_PAT` secret set on
*this* repo (`Contents: read and write`, with every target repo in the
token's allowlist if it's fine-grained) — add it via
`gh secret set HOMELAB_PAT --repo paviduz/ps-shared-workflows` before relying
on the automatic fan-out; until then, trigger `agents-md-sync.yml` manually
(`workflow_dispatch`) in each repo after editing the shared file.

AGENTS.md is the reliable, cross-tool snapshot (Cursor, Copilot, Codex,
Gemini CLI read it natively). Claude Code instead imports
`AGENTS.repo.md` and `defaults/AGENTS.shared.md` directly, live, via
`CLAUDE.md`'s `@path` syntax — see homelab-infra/decisions/ for why both
exist side by side.

The same job also runs `scripts/Test-ClaudeImports.ps1` against the calling
repo's `CLAUDE.md` (or `.claude/CLAUDE.md`), failing the run if any `@import`
resolves to a path that doesn't exist. Claude Code itself silently skips a
missing import rather than erroring, so this is the only thing that would
ever catch one — worth having given how easy it is to miscount `../` depth
for a `CLAUDE.md` living in a subdirectory (`.claude/CLAUDE.md`'s imports
resolve one level deeper than a root `CLAUDE.md`'s).

### `ps-quality-gate.yml`

Runs two parallel jobs against any PowerShell repository:

| Job | What it runs | Fail condition |
| --- | --- | --- |
| `static-analysis` | `Invoke-ScriptAnalyzer` + security rule scan | Any `Error` finding; optionally `Warning` |
| `pester-tests` | `Invoke-Pester` v5 | Any failing test |

## Usage

Add a workflow file to your repository:

```yaml
# .github/workflows/ps-quality.yml
name: PowerShell Quality Gate

on:
  push:
    branches: [main]
    paths: ['**/*.ps1', '**/*.psm1', '**/*.psd1']
  pull_request:
    paths: ['**/*.ps1', '**/*.psm1', '**/*.psd1']

jobs:
  ps-quality:
    uses: paviduz/ps-shared-workflows/.github/workflows/ps-quality-gate.yml@main
    with:
      ps-path: './src'
      test-path: './tests'
```

## Inputs

| Input | Default | Description |
| --- | --- | --- |
| `ps-path` | `.` | Path to PS files or directory to analyse |
| `settings-path` | `PSScriptAnalyzerSettings.psd1` | Repo-relative path to your settings file |
| `test-path` | _(empty)_ | Path to Pester tests. Omit to skip testing stage |
| `fail-on-warning` | `false` | Treat `Warning` findings as failures |
| `pester-verbosity` | `Normal` | Pester output level: Minimal, Normal, Detailed, Diagnostic |
| `runner` | `ubuntu-latest` | GitHub-hosted runner image |

## Settings resolution

The workflow resolves settings in this priority order:

1. Calling repo's `PSScriptAnalyzerSettings.psd1` (or path from `settings-path` input)
2. `defaults/PSScriptAnalyzerSettings.psd1` in this repository
3. PSScriptAnalyzer built-in defaults (Error + Warning severity)

To configure your own rules, copy
`defaults/PSScriptAnalyzerSettings.psd1` to your repository root and edit it.
A full annotated template is also available in
[`paviduz/Homelab-Agent-Platform-Plan`](https://github.com/paviduz/Homelab-Agent-Platform-Plan)
at `.github/skills/ps-quality-pipeline/templates/PSScriptAnalyzerSettings.psd1`.

## Relationship to the PS agent team

This workflow automates the deterministic stages of the five-stage quality pipeline
defined in `paviduz/Homelab-Agent-Platform-Plan`:

| Pipeline stage | Automated here | Agent (interactive) |
| --- | --- | --- |
| 1 — Static analysis | `static-analysis` job | `ps-reviewer` |
| 2 — Security audit (rule-based) | `static-analysis` job | `ps-auditor` |
| 3 — Refactor | No | `ps-refactorer` |
| 4 — Tests | `pester-tests` job | `ps-tester` |
| 5 — Documentation | No | `ps-documenter` |

Stages 3 and 5 require an LLM and are handled by the agent team, not CI.
