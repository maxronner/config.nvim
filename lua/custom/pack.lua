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

local function normalize_specs(inputs)
  return M.spec.normalize(inputs)
end

local function resolve_specs(normalized, opts)
  local backend_name = opts.backend or "vim_pack"
  local backend = require("custom.pack.backends." .. backend_name)
  return backend.resolve(normalized, opts)
end

local function validate_specs(resolved, opts)
  return M.policy.validate(resolved, {
    mode = opts.mode,
    trusted_prefix = opts.trusted_prefix,
  })
end

local function install_specs(resolved)
  M.loader.setup(resolved)
end

function M.setup(inputs, opts)
  opts = opts or {}

  local normalized = normalize_specs(inputs)
  local resolved = resolve_specs(normalized, opts)
  validate_specs(resolved, opts)
  install_specs(resolved)
end

return M
