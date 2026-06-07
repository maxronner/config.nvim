local M = {}

function M.config_root()
  return vim.g.custom_config_root or vim.env.NVIM_PACK_CONFIG_ROOT or vim.fn.stdpath("config")
end

function M.local_pack_root()
  return vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
end

return M
