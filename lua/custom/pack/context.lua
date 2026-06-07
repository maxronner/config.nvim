local M = {}

local function default_filereadable(path)
  return vim.fn.filereadable(path) == 1
end

function M.resolve(opts)
  opts = opts or {}
  local env = opts.env or vim.env
  local filereadable = opts.filereadable or default_filereadable

  local config_root = env.NVIM_PACK_CONFIG_ROOT or vim.fn.stdpath("config")
  local manifest = env.NVIM_PACK_MANIFEST or vim.fs.joinpath(config_root, "lua", "custom", "pack", "manifest.lua")
  local backend = env.NVIM_PACK_BACKEND

  if not backend then
    backend = filereadable(manifest) and "nix_manifest" or "vim_pack"
  end

  local mode = env.NVIM_PACK_MODE
  if backend == "nix_manifest" then
    mode = mode or "secure"
  end

  return {
    config_root = config_root,
    manifest = manifest,
    backend = backend,
    mode = mode,
    trusted_prefix = env.NVIM_PACK_TRUSTED_PREFIX,
  }
end

function M.apply(context)
  vim.g.custom_config_root = context.config_root

  if context.backend == "nix_manifest" then
    vim.env.NVIM_TREESITTER_INSTALL = vim.env.NVIM_TREESITTER_INSTALL or "disabled"
  end
end

function M.current(opts)
  local context = M.resolve(opts)
  M.apply(context)
  return context
end

return M
