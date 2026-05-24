local M = {}

function M.validate(resolved, opts)
  opts = opts or {}
  if opts.mode ~= "secure" then
    return
  end

  local trusted_prefix = opts.trusted_prefix or "/nix/store/"

  for _, plugin in ipairs(resolved) do
    assert(plugin.rev, plugin.name .. ": missing rev")
    assert(plugin.sha256, plugin.name .. ": missing sha256")
    assert(plugin.runtime_path, plugin.name .. ": missing runtime_path")
    assert(vim.startswith(plugin.runtime_path, trusted_prefix), plugin.name .. ": untrusted path")
  end
end

return M
