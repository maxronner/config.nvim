vim.g.custom_start_time = vim.uv.hrtime()
vim.g.mapleader = " "

local config_root = vim.env.NVIM_PACK_CONFIG_ROOT or vim.fn.stdpath("config")
vim.opt.runtimepath:prepend(config_root)

local context = require("custom.pack.context").current()

local pack = require("custom.pack")
local specs = require("custom.pack.specs").get()

pack.setup(specs, {
  backend = context.backend,
  manifest = context.manifest,
  mode = context.mode,
  trusted_prefix = context.trusted_prefix,
})
