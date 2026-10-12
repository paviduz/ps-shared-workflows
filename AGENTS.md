# ps-shared-workflows

Public repo: the reusable `ps-quality-gate.yml` workflow (PSScriptAnalyzer + Pester) and its
default `defaults/PSScriptAnalyzerSettings.psd1`. Changes here affect every caller on `@main`,
so keep inputs backward compatible.

System-wide working rules and the work list live in **paviduz/brain** (`AGENTS.md`, GitHub Issues).
Never put secrets or private-repo details here: this repo is public.
