local M = {}

function M.resolve(specs, opts)
  opts = opts or {}

  local pack_specs = vim.tbl_map(function(spec)
    return {
      src = spec.source,
      name = spec.name,
      version = spec.rev,
    }
  end, specs)

  vim.pack.add(pack_specs, {
    confirm = opts.confirm == true,
    load = false,
  })

  return specs
end

return M
