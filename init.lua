vim.g.custom_start_time = vim.uv.hrtime()
vim.g.mapleader = " "

local config_root = vim.env.NVIM_PACK_CONFIG_ROOT or vim.fn.stdpath("config")
vim.opt.runtimepath:prepend(config_root)

local pack_manifest = vim.env.NVIM_PACK_MANIFEST or (config_root .. "/lua/custom/pack/manifest.lua")
local pack_backend = vim.env.NVIM_PACK_BACKEND

if not pack_backend then
  pack_backend = vim.fn.filereadable(pack_manifest) == 1 and "nix_manifest" or "vim_pack"
end

local pack_mode = vim.env.NVIM_PACK_MODE
if pack_backend == "nix_manifest" then
  pack_mode = pack_mode or "secure"
  vim.env.NVIM_TREESITTER_INSTALL = vim.env.NVIM_TREESITTER_INSTALL or "disabled"
end

local pack = require("custom.pack")
local specs = require("custom.pack.specs").get()

pack.setup(specs, {
  backend = pack_backend,
  manifest = pack_manifest,
  mode = pack_mode,
  trusted_prefix = vim.env.NVIM_PACK_TRUSTED_PREFIX,
})
