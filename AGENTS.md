# Agent Instructions

- This is a vim.pack config. Plugin specs are declared in `lua/custom/pack/specs.lua`.
- `nvim-pack-lock.json` is local mutable vim.pack state and is intentionally ignored.
- Verify this checkout explicitly, because plain `nvim` may load the Nix-installed config rather than the current working tree.
- If using Nix/flake checks later, `git add` new files first so the flake can see them.
