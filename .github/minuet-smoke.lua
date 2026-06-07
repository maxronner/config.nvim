local pack = require("custom.pack")
local loader = require("custom.pack.loader")

local function contains(value, expected)
  if type(value) == "table" then
    return vim.tbl_contains(value, expected)
  end

  return value == expected
end

local seen = {}
for _, plugin in ipairs(pack.normalize(require("custom.pack.specs").get())) do
  seen[plugin.name] = plugin
end

local spec = seen["minuet-ai.nvim"]
assert(spec, "minuet-ai.nvim spec missing")
assert(spec.lazy == true, "minuet-ai.nvim should be lazy loaded")
assert(contains(spec.cmd, "Minuet"), "minuet-ai.nvim should lazy load on :Minuet")
assert(contains(spec.event, "InsertEnter"), "minuet-ai.nvim should lazy load on InsertEnter")

pack.setup(require("custom.pack.specs").get())

local in_loader = false
for _, row in ipairs(loader.status()) do
  if row.name == "minuet-ai.nvim" then
    in_loader = true
    break
  end
end

assert(in_loader, "minuet-ai.nvim missing from pack loader")
loader.load("minuet-ai.nvim")
assert(loader.is_loaded("minuet-ai.nvim"), "minuet-ai.nvim did not load")
assert(package.loaded.minuet, "minuet module was not loaded")
assert(vim.fn.exists(":Minuet") == 2, ":Minuet command missing after setup")
