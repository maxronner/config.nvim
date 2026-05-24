local M = {}

M.spec = require("custom.pack.spec")
M.policy = require("custom.pack.policy")
M.loader = require("custom.pack.loader")

function M.import(...)
  return M.spec.import(...)
end

function M.normalize(...)
  return M.spec.normalize(...)
end

function M.setup(inputs, opts)
  opts = opts or {}

  local backend_name = opts.backend or "vim_pack"
  local backend = require("custom.pack.backends." .. backend_name)
  local normalized = M.spec.normalize(inputs)
  local resolved = backend.resolve(normalized, opts)

  M.policy.validate(resolved, {
    mode = opts.mode,
    trusted_prefix = opts.trusted_prefix,
  })

  M.loader.setup(resolved)
end

return M
