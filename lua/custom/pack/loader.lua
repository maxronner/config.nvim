local spec = require("custom.pack.spec")

local M = {}
local state = {
  plugins = {},
  loaded = {},
  loading = {},
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

local function load_dependencies(plugin)
  for _, dependency in ipairs(plugin.dependencies) do
    if state.plugins[dependency] then
      M.load(dependency)
    end
  end
end

local function add_runtime(plugin)
  if plugin.runtime_path then
    vim.opt.runtimepath:prepend(plugin.runtime_path)
    source_runtime_files(plugin.runtime_path)
  else
    vim.cmd.packadd(plugin.name)
  end
end

function M.load(name)
  if state.loaded[name] then
    return
  end
  if state.loading[name] then
    error(("Recursive pack plugin load: %s"):format(name))
  end

  local plugin = state.plugins[name]
  if not plugin then
    error(("Unknown pack plugin: %s"):format(name))
  end

  state.loading[name] = true
  local ok, err = xpcall(function()
    load_dependencies(plugin)
    add_runtime(plugin)
    configure(plugin)
  end, debug.traceback)
  state.loading[name] = nil

  if not ok then
    error(err, 0)
  end

  state.loaded[name] = true
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

local function lazy_key_action(key)
  if type(key) ~= "table" then
    return nil
  end
  return key[2]
end

local function lazy_key_is_trigger(action)
  return action == nil
end

local function invoke_lazy_key(action, lhs)
  if type(action) == "function" then
    return action()
  end
  return vim.api.nvim_feedkeys(vim.keycode(action or lhs), "m", false)
end

local function key_trigger(plugin, key)
  local lhs = key
  local modes = { "n" }
  local key_opts = {}

  if type(key) == "table" then
    lhs = key[1]
    modes = spec.as_list(key.mode or "n")
    key_opts = key
  end
  local action = lazy_key_action(key)

  local map_opts = {
    desc = key_opts.desc,
    silent = key_opts.silent,
    expr = key_opts.expr,
    noremap = key_opts.remap ~= true,
  }

  return {
    kind = "key",
    plugin = plugin.name,
    lhs = lhs,
    modes = modes,
    action = action,
    map_opts = map_opts,
  }
end

local function setup_key(plugin, trigger)
  local lhs = trigger.lhs
  local modes = trigger.modes
  local action = trigger.action

  vim.keymap.set(modes, lhs, function()
    M.load(plugin.name)

    if lazy_key_is_trigger(action) then
      pcall(vim.keymap.del, modes, lhs)
    end

    return invoke_lazy_key(action, lhs)
  end, trigger.map_opts)
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

function M.install_trigger(plugin, trigger)
  if trigger.kind == "command" then
    setup_cmd(plugin, trigger.command)
  elseif trigger.kind == "key" then
    setup_key(plugin, trigger)
  elseif trigger.kind == "event" then
    setup_event(plugin, trigger.event)
  else
    error(("%s: unknown pack trigger kind %s"):format(plugin.name, tostring(trigger.kind)))
  end
end

function M.trigger_plan(plugin)
  local triggers = {}

  for _, command in ipairs(spec.as_list(plugin.cmd)) do
    table.insert(triggers, {
      kind = "command",
      plugin = plugin.name,
      command = command,
    })
  end

  for _, key in ipairs(spec.as_list(plugin.keys)) do
    table.insert(triggers, key_trigger(plugin, key))
  end

  for _, event in ipairs(spec.as_list(plugin.event)) do
    table.insert(triggers, {
      kind = "event",
      plugin = plugin.name,
      event = event,
    })
  end

  return triggers
end

local function setup_triggers(plugin)
  for _, trigger in ipairs(M.trigger_plan(plugin)) do
    M.install_trigger(plugin, trigger)
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

function M.build_plugin_index(resolved)
  local plugins = {}

  for _, plugin in ipairs(resolved) do
    if plugins[plugin.name] then
      error(("duplicate pack plugin: %s"):format(plugin.name))
    end
    plugins[plugin.name] = plugin
  end

  validate_dependencies(resolved, plugins)
  return plugins
end

function M.setup(resolved)
  local plugins = M.build_plugin_index(resolved)
  state.plugins = plugins
  state.loaded = {}
  state.loading = {}

  for _, plugin in ipairs(resolved) do
    if plugin.lazy then
      setup_triggers(plugin)
    else
      M.load(plugin.name)
    end
  end
end

return M
