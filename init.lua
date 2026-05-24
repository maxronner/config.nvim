vim.g.mapleader = " "
vim.go.loadplugins = false
vim.env.NVIM_TREESITTER_INSTALL = vim.env.NVIM_TREESITTER_INSTALL or "disabled"

local config_root = vim.env.NVIM_PACK_CONFIG_ROOT or vim.fn.stdpath("config")
vim.opt.runtimepath:prepend(config_root)

local function source_runtime_files(root)
  for _, pattern in ipairs({ "plugin/**/*.vim", "plugin/**/*.lua" }) do
    for _, file in ipairs(vim.fn.globpath(root, pattern, false, true)) do
      vim.cmd.source(vim.fn.fnameescape(file))
    end
  end
end

local pack = require("custom.pack")
local specs = require("custom.pack.specs").get()

pack.setup(specs, {
  backend = vim.env.NVIM_PACK_BACKEND or "vim_pack",
  manifest = vim.env.NVIM_PACK_MANIFEST or (config_root .. "/lua/custom/pack/manifest.lua"),
  mode = vim.env.NVIM_PACK_MODE,
  trusted_prefix = vim.env.NVIM_PACK_TRUSTED_PREFIX,
})

source_runtime_files(config_root)
