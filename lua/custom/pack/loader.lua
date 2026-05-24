local spec = require("custom.pack.spec")

local M = {}
local state = {
  plugins = {},
  loaded = {},
}

local function configure(plugin)
  if plugin.config then
    local ok, err = pcall(plugin.config)
    if not ok then
      error(("Failed to configure %s: %s"):format(plugin.name, err))
    end
  elseif plugin.opts then
    local ok, module = pcall(require, plugin.main)
    if not ok then
      error(("Failed to load setup module for %s: %s"):format(plugin.name, module))
    end

    ok, module = pcall(module.setup, plugin.opts)
    if not ok then
      error(("Failed to configure %s: %s"):format(plugin.name, module))
    end
  end
end

local function source_runtime_files(runtime_path)
  for _, pattern in ipairs({ "plugin/**/*.vim", "plugin/**/*.lua", "ftdetect/**/*.vim", "ftdetect/**/*.lua" }) do
    for _, file in ipairs(vim.fn.globpath(runtime_path, pattern, false, true)) do
      vim.cmd.source(vim.fn.fnameescape(file))
    end
  end
end

function M.load(name)
  if state.loaded[name] then
    return
  end

  local plugin = state.plugins[name]
  if not plugin then
    error(("Unknown pack plugin: %s"):format(name))
  end

  for _, dependency in ipairs(plugin.dependencies) do
    if state.plugins[dependency] then
      M.load(dependency)
    end
  end

  if plugin.runtime_path then
    vim.opt.runtimepath:prepend(plugin.runtime_path)
    source_runtime_files(plugin.runtime_path)
  else
    vim.cmd.packadd(plugin.name)
  end

  state.loaded[name] = true
  configure(plugin)
end

function M.is_loaded(name)
  return state.loaded[name] == true
end

function M.loaded()
  local names = {}
  for name in pairs(state.loaded) do
    table.insert(names, name)
  end
  table.sort(names)
  return names
end

function M.counts()
  local loaded = 0
  local total = 0

  for name in pairs(state.plugins) do
    total = total + 1
    if M.is_loaded(name) then
      loaded = loaded + 1
    end
  end

  return {
    loaded = loaded,
    total = total,
  }
end

function M.status()
  local rows = {}
  for name, plugin in pairs(state.plugins) do
    table.insert(rows, {
      name = name,
      lazy = plugin.lazy,
      loaded = M.is_loaded(name),
    })
  end

  table.sort(rows, function(a, b)
    if a.loaded ~= b.loaded then
      return a.loaded
    end
    return a.name < b.name
  end)

  return rows
end

local function setup_cmd(plugin, command)
  vim.api.nvim_create_user_command(command, function(ctx)
    pcall(vim.api.nvim_del_user_command, command)
    M.load(plugin.name)

    local args = ctx.args ~= "" and (" " .. ctx.args) or ""
    local mods = ctx.mods ~= "" and (ctx.mods .. " ") or ""
    vim.cmd(mods .. command .. args)
  end, {
    bang = true,
    bar = true,
    complete = "file",
    nargs = "*",
  })
end

local function setup_key(plugin, key)
  local lhs = key[1]
  local rhs = key[2]
  local modes = spec.as_list(key.mode or "n")
  local map_opts = {
    desc = key.desc,
    silent = key.silent,
    expr = key.expr,
    noremap = key.remap ~= true,
  }

  vim.keymap.set(modes, lhs, function()
    pcall(vim.keymap.del, modes, lhs)
    M.load(plugin.name)
    if type(rhs) == "function" then
      return rhs()
    end
    return vim.api.nvim_feedkeys(vim.keycode(rhs or lhs), "m", false)
  end, map_opts)
end

local function setup_event(plugin, event)
  local autocmd = event
  local opts = {
    desc = "Load pack plugin " .. plugin.name,
    once = true,
    callback = function()
      M.load(plugin.name)
    end,
  }

  vim.api.nvim_create_autocmd(autocmd, opts)
end

local function setup_triggers(plugin)
  for _, command in ipairs(spec.as_list(plugin.cmd)) do
    setup_cmd(plugin, command)
  end

  for _, key in ipairs(spec.as_list(plugin.keys)) do
    setup_key(plugin, key)
  end

  for _, event in ipairs(spec.as_list(plugin.event)) do
    setup_event(plugin, event)
  end
end

local function validate_dependencies(resolved, plugins)
  for _, plugin in ipairs(resolved) do
    for _, dependency in ipairs(plugin.dependencies) do
      if not plugins[dependency] then
        error(("%s: unknown pack dependency %s"):format(plugin.name, dependency))
      end
    end
  end
end

function M.setup(resolved)
  local plugins = {}

  for _, plugin in ipairs(resolved) do
    if plugins[plugin.name] then
      error(("duplicate pack plugin: %s"):format(plugin.name))
    end
    plugins[plugin.name] = plugin
  end

  validate_dependencies(resolved, plugins)

  state.plugins = plugins
  state.loaded = {}

  for _, plugin in ipairs(resolved) do
    if plugin.lazy then
      setup_triggers(plugin)
    else
      M.load(plugin.name)
    end
  end
end

return M
