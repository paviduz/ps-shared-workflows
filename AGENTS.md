# ps-shared-workflows

This repo is the canonical source of `defaults/AGENTS.shared.md`, the
project-wide conventions block synced into every other repo in the
homelab-infra / context-engine / personal-brain cluster (homelab-infra,
homelab-context, personal-brain, homelab-tools, context-engine,
knowledge-server) via `agents-md-sync.yml`.

Edit `defaults/AGENTS.shared.md` carefully: a change here propagates to every
repo in the cluster via `notify-agents-md-change.yml`. This file
(`AGENTS.md`) is hand-written, not generated — this repo has no separate
"local" conventions layer, since it doesn't consume the shared file it
produces.

This repo is public. Don't add anything homelab-specific, personal, or
secret-bearing here — it's reusable workflow/tooling only, by design (see
`decisions/2026-04-24-ps-shared-workflows-public.md` in homelab-infra).
