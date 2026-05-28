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

local pack = require("custom.pack")
local resolve = require("custom.pack.resolve")

local function assert_same(value, expected, message)
  assert(vim.deep_equal(value, expected), message)
end

local function fixture_specs()
  return pack.normalize({
    {
      "owner/example.nvim",
      version = "v1",
      dependencies = {
        "owner/example-dependency.nvim",
      },
    },
  })
end

local function write_manifest(specs)
  local manifest_path = vim.fs.joinpath(vim.fn.stdpath("cache"), "pack-smoke-manifest.lua")
  vim.fn.mkdir(vim.fn.fnamemodify(manifest_path, ":h"), "p")

  local manifest_file = assert(io.open(manifest_path, "w"))
  manifest_file:write("return {\n")
  for _, plugin in ipairs(specs) do
    manifest_file:write(
      ("  [%q] = { runtime_path = %q, rev = %q, sha256 = %q },\n"):format(
        plugin.name,
        "/nix/store/example-" .. plugin.name,
        "manifest-rev",
        "manifest-sha256"
      )
    )
  end
  manifest_file:write("}\n")
  manifest_file:close()

  return manifest_path
end

local function assert_imports_and_normalization()
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

  local seen = {}
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
end

local function assert_resolved_spec_shape(specs, normalized_before_resolve)
  assert(specs[1].runtime_path == nil, "normalized spec should not have runtime_path")

  local primary_spec = specs[#specs]
  local helper_resolved = resolve.enrich(primary_spec, {
    runtime_path = "/tmp/example.nvim",
  })
  assert_same(specs, normalized_before_resolve, "resolve.enrich should not mutate normalized specs")
  assert(helper_resolved ~= primary_spec, "resolve.enrich should return a new resolved spec")
  assert(helper_resolved.runtime_path == "/tmp/example.nvim", "resolved spec should include runtime_path")

  local ok, err = pcall(resolve.enrich, primary_spec, {})
  assert(not ok, "resolve.enrich should reject missing runtime_path")
  assert(
    tostring(err):find("example.nvim: resolved pack spec missing runtime_path", 1, true),
    "missing runtime_path error was not useful"
  )
end

local function assert_backend_resolution(specs, normalized_before_resolve)
  local pack_root = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "core", "opt")
  for _, plugin in ipairs(specs) do
    vim.fn.mkdir(vim.fs.joinpath(pack_root, plugin.name), "p")
  end

  local vim_pack_resolved = require("custom.pack.backends.vim_pack").resolve(specs)
  assert_same(specs, normalized_before_resolve, "vim_pack backend should not mutate normalized specs")
  assert(vim_pack_resolved[1] ~= specs[1], "vim_pack backend should return new resolved specs")
  assert(vim_pack_resolved[1].runtime_path, "vim_pack resolved spec should have runtime_path")
  assert(specs[1].runtime_path == nil, "normalized spec should remain unresolved after vim_pack resolve")

  local nix_resolved = require("custom.pack.backends.nix_manifest").resolve(specs, {
    manifest = write_manifest(specs),
  })
  assert_same(specs, normalized_before_resolve, "nix_manifest backend should not mutate normalized specs")
  assert(nix_resolved[1] ~= specs[1], "nix_manifest backend should return new resolved specs")
  assert(nix_resolved[1].runtime_path, "nix_manifest resolved spec should have runtime_path")
  assert(nix_resolved[1].rev == "manifest-rev", "nix_manifest resolved spec should prefer manifest rev")
  assert(nix_resolved[1].sha256 == "manifest-sha256", "nix_manifest resolved spec should include manifest sha256")
end

local function assert_loader_validation(loader)
  local total_before_bad_setup = loader.counts().total
  local ok, err = pcall(loader.setup, {
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
end

local function assert_loader_trigger_plan(loader)
  local function key_action() end
  local triggers = loader.trigger_plan({
    name = "planned-plugin",
    cmd = { "Planned" },
    keys = {
      "gp",
      { "<leader>p", key_action, mode = { "n", "x" }, desc = "Planned key", silent = true },
    },
    event = { "BufReadPost" },
  })

  assert(#triggers == 4, "loader trigger plan should include commands, keys, and events")
  assert(triggers[1].kind == "command", "first trigger should be command")
  assert(triggers[1].plugin == "planned-plugin", "command trigger missing plugin name")
  assert(triggers[1].command == "Planned", "command trigger missing command")

  assert(triggers[2].kind == "key", "second trigger should be key")
  assert(triggers[2].lhs == "gp", "string key trigger missing lhs")
  assert_same(triggers[2].modes, { "n" }, "string key trigger should default to normal mode")
  assert(triggers[2].action == nil, "string key trigger should replay lhs")
  assert(triggers[2].map_opts.noremap == true, "key trigger should default to noremap")

  assert(triggers[3].kind == "key", "third trigger should be key")
  assert(triggers[3].lhs == "<leader>p", "table key trigger missing lhs")
  assert_same(triggers[3].modes, { "n", "x" }, "table key trigger should preserve modes")
  assert(triggers[3].action == key_action, "table key trigger missing action")
  assert(triggers[3].map_opts.desc == "Planned key", "table key trigger missing desc")
  assert(triggers[3].map_opts.silent == true, "table key trigger missing silent")
  assert(triggers[3].map_opts.noremap == true, "table key trigger should default to noremap")

  assert(triggers[4].kind == "event", "fourth trigger should be event")
  assert(triggers[4].event == "BufReadPost", "event trigger missing event")

  local ok, err = pcall(loader.install_trigger, { name = "planned-plugin" }, { kind = "timer" })
  assert(not ok, "loader.install_trigger should reject unknown trigger kinds")
  assert(
    tostring(err):find("planned-plugin: unknown pack trigger kind timer", 1, true),
    "unknown trigger kind error was not useful"
  )
end

local function assert_loader_runtime(loader)
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

  loader.load("mini.starter")
  loaded = loader.loaded()
  counts = loader.counts()
  assert(counts.loaded == #loaded, "counts.loaded mismatch after starter load")

  local footer = require("custom.starter").footer()
  assert(
    footer:find(("loaded %d/%d plugins"):format(counts.loaded, counts.total), 1, true),
    "starter footer missing pack stats"
  )
end

local function assert_loaded_config()
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
end

local specs = fixture_specs()
local normalized_before_resolve = vim.deepcopy(specs)

assert_imports_and_normalization()
assert_resolved_spec_shape(specs, normalized_before_resolve)
assert_backend_resolution(specs, normalized_before_resolve)

for _, module in ipairs({ "cmp", "luasnip", "cmp_nvim_lsp" }) do
  assert(not package.loaded[module], ("pack startup loaded %s too early"):format(module))
end

local loader = require("custom.pack.loader")
assert_loader_validation(loader)
assert_loader_trigger_plan(loader)
assert_loader_runtime(loader)
assert_loaded_config()
