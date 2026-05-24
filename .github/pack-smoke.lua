local forbidden_specs = {
  "LuaSnip",
  "cmp-buffer",
  "cmp-cmdline",
  "cmp_luasnip",
  "cmp-nvim-lsp",
  "cmp-path",
  "friendly-snippets",
  "fidget.nvim",
  "lazydev.nvim",
  "lspkind.nvim",
  "mini.comment",
  "nvim-cmp",
  "nvim-lspconfig",
}

local seen = {}
local pack = require("custom.pack")

local ok, err = pcall(pack.import, "custom.plugins.mini", {
  include = {
    "mini.statsline",
  },
})
assert(not ok, "pack.import should reject missing includes")
assert(
  tostring(err):find("missing included pack specs: mini.statsline", 1, true),
  "missing include error was not useful"
)

for _, plugin in ipairs(pack.normalize(require("custom.pack.specs").get())) do
  seen[plugin.name] = true
end

for _, spec in ipairs(pack.import("custom.plugins.mini")) do
  local name = pack.spec.spec_name(spec)
  assert(seen[name], ("pack specs should include %s"):format(name))
end

for _, name in ipairs(forbidden_specs) do
  assert(not seen[name], ("pack specs should not include %s"):format(name))
end

for _, module in ipairs({ "cmp", "luasnip", "cmp_nvim_lsp" }) do
  assert(not package.loaded[module], ("pack startup loaded %s too early"):format(module))
end

local loader = require("custom.pack.loader")
local total_before_bad_setup = loader.counts().total
ok, err = pcall(loader.setup, {
  {
    name = "duplicate-plugin",
    dependencies = {},
    lazy = true,
  },
  {
    name = "duplicate-plugin",
    dependencies = {},
    lazy = true,
  },
})
assert(not ok, "loader.setup should reject duplicate plugins")
assert(tostring(err):find("duplicate pack plugin: duplicate-plugin", 1, true), "duplicate plugin error was not useful")
assert(loader.counts().total == total_before_bad_setup, "duplicate setup mutated loader state")

ok, err = pcall(loader.setup, {
  {
    name = "broken-plugin",
    dependencies = {
      "missing-plugin",
    },
    lazy = true,
  },
})
assert(not ok, "loader.setup should reject unknown dependencies")
assert(
  tostring(err):find("broken-plugin: unknown pack dependency missing-plugin", 1, true),
  "unknown dependency error was not useful"
)
assert(loader.counts().total == total_before_bad_setup, "missing dependency setup mutated loader state")

assert(not loader.is_loaded("SchemaStore.nvim"), "SchemaStore.nvim loaded before smoke request")

loader.load("SchemaStore.nvim")
assert(loader.is_loaded("SchemaStore.nvim"), "SchemaStore.nvim did not report loaded")

local loaded = loader.loaded()
assert(vim.tbl_contains(loaded, "SchemaStore.nvim"), "loaded list missing SchemaStore.nvim")

local counts = loader.counts()
assert(counts.loaded == #loaded, "counts.loaded does not match loaded list")

local status = loader.status()
local has_pending = false
for _, row in ipairs(status) do
  if row.name == "SchemaStore.nvim" then
    assert(row.loaded == true, "status reports SchemaStore.nvim pending")
  elseif row.lazy and not row.loaded then
    has_pending = true
  end
end
assert(has_pending, "status should include pending lazy plugins")

require("custom.pack.loader").load("mini.starter")
loaded = loader.loaded()
counts = loader.counts()
status = loader.status()
assert(counts.loaded == #loaded, "counts.loaded mismatch after starter load")

local footer = require("custom.starter").footer()
assert(
  footer:find(("loaded %d/%d plugins"):format(counts.loaded, counts.total), 1, true),
  "starter footer missing pack stats"
)

local lua_ls = vim.lsp.config.lua_ls
assert(lua_ls, "lua_ls config missing")
assert(
  lua_ls.capabilities.textDocument.completion.completionItem.snippetSupport == true,
  "native LSP capabilities must advertise snippet support"
)

for _, module in ipairs({ "cmp", "luasnip", "cmp_nvim_lsp" }) do
  assert(not package.loaded[module], ("pack startup should not load %s"):format(module))
end

vim.cmd("enew")
vim.bo.filetype = "lua"
require("custom.native_snippets").expand("req")
assert(vim.api.nvim_get_current_line():match("^local "), "native snippet expansion failed")
