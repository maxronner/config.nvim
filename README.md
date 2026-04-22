# Neovim Configuration

Personal Neovim setup from my dotfiles.

This repo is tuned for my machine and workflow, so it is not intended to be a drop-in config. Still, if you want to browse the setup, steal ideas, or inspect how things are organized, feel free.

## Layout

- `init.lua` starts the config
- `lua/` holds most of the Lua modules
- `plugin/` contains plugin entrypoints and setup
- `after/` is for overrides that load later
- `colors/` includes colorscheme files
- `tests/` contains config tests

## Note

Expect machine-specific assumptions, local preferences, and rough edges that make sense in a personal dotfiles repo.
