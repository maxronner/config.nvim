local M = {}

function M.enrich(spec, fields)
  fields = fields or {}

  if not fields.runtime_path or fields.runtime_path == "" then
    error(("%s: resolved pack spec missing runtime_path"):format(spec.name or "<unknown>"))
  end

  return vim.tbl_extend("force", spec, fields)
end

function M.map(specs, resolve_one)
  return vim.tbl_map(function(spec)
    return M.enrich(spec, resolve_one(spec))
  end, specs)
end

return M
