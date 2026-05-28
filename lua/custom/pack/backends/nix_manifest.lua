local M = {}
local resolve = require("custom.pack.resolve")

local function load_manifest(path)
  local ok, manifest = pcall(dofile, path)
  if not ok then
    error(("Failed to load pack manifest %s: %s"):format(path, manifest))
  end
  if type(manifest) ~= "table" then
    error("Pack manifest must return a table")
  end
  return manifest
end

function M.resolve(specs, opts)
  opts = opts or {}
  local manifest_path = opts.manifest or vim.env.NVIM_PACK_MANIFEST
  if not manifest_path or manifest_path == "" then
    error("nix_manifest backend requires opts.manifest or NVIM_PACK_MANIFEST")
  end

  local manifest = load_manifest(manifest_path)

  return resolve.map(specs, function(spec)
    local entry = manifest[spec.name]
    if not entry then
      error("No manifest entry for " .. spec.name)
    end

    return {
      runtime_path = entry.runtime_path,
      rev = entry.rev or spec.rev,
      sha256 = entry.sha256 or spec.sha256,
    }
  end)
end

return M
