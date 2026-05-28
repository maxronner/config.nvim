local M = {}

function M.resolve(specs, opts)
  opts = opts or {}

  local pack_root = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
  local all_installed = true
  local pack_specs = vim.tbl_map(function(spec)
    local runtime_path = vim.fs.joinpath(pack_root, spec.name)
    all_installed = all_installed and vim.uv.fs_stat(runtime_path) ~= nil

    return {
      src = spec.source,
      name = spec.name,
      version = spec.rev,
    }
  end, specs)

  if opts.sync == true or vim.env.NVIM_PACK_SYNC == "1" or not all_installed then
    vim.pack.add(pack_specs, {
      confirm = opts.confirm == true,
      load = false,
    })
  end

  return vim.tbl_map(function(spec)
    return vim.tbl_extend("force", spec, {
      runtime_path = vim.fs.joinpath(pack_root, spec.name),
    })
  end, specs)
end

return M
