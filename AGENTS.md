# Agent Instructions

- This is a vim.pack config. Plugin specs are declared in `lua/custom/pack/specs.lua`.
- `nvim-pack-lock.json` is local mutable vim.pack state and is intentionally ignored.
- Verify this checkout explicitly, because plain `nvim` may load the Nix-installed config rather than the current working tree.
- If using Nix/flake checks later, `git add` new files first so the flake can see them.

## Agent skills

### Issue tracker

Issues and PRDs live as local markdown files under `.scratch/`. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default filesystem markdown triage vocabulary. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repo: read `CONTEXT.md` and `docs/adr/` when present. See `docs/agents/domain.md`.
