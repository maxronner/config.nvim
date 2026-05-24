local M = {}

function M.as_list(value)
  if value == nil then
    return {}
  end
  if type(value) == "table" then
    return value
  end
  return { value }
end

function M.plugin_name(repo)
  return repo:match("([^/]+)$")
end

function M.plugin_source(repo)
  if repo:match("^https?://") or repo:match("^git@") then
    return repo
  end

  return "https://github.com/" .. repo
end

function M.spec_name(input)
  return input.name or M.plugin_name(input[1] or "")
end

function M.main_module_name(input)
  if input.main then
    return input.main
  end

  local name = M.spec_name(input)
  name = name:gsub("%.nvim$", "")
  name = name:gsub("^nvim%-", "")
  return name
end

local function normalize_module_specs(module_specs)
  if type(module_specs) ~= "table" then
    error("pack plugin module must return a table")
  end

  if type(module_specs[1]) == "string" then
    return { module_specs }
  end

  return module_specs
end

local function append_spec(inputs, input, seen)
  if type(input) == "string" then
    input = { input }
  end

  local name = M.spec_name(input)
  if name == "" or seen[name] or input.enabled == false then
    return
  end
  seen[name] = true

  for _, dependency in ipairs(M.as_list(input.dependencies)) do
    append_spec(inputs, dependency, seen)
  end

  table.insert(inputs, input)
end

local function mark_available(input, available)
  if type(input) == "string" then
    input = { input }
  end

  available[M.spec_name(input)] = true
  for _, dependency in ipairs(M.as_list(input.dependencies)) do
    mark_available(dependency, available)
  end
end

function M.import(module_names, opts)
  opts = opts or {}

  local include = {}
  local missing = {}
  local available = {}
  for _, name in ipairs(M.as_list(opts.include)) do
    include[name] = true
    missing[name] = true
  end

  local imported = {}
  for _, module_name in ipairs(M.as_list(module_names)) do
    local module_specs = normalize_module_specs(require(module_name))
    for _, spec in ipairs(module_specs) do
      mark_available(spec, available)

      local name = M.spec_name(spec)
      if not opts.include or include[name] then
        table.insert(imported, spec)
      end
    end
  end

  if opts.include then
    for name in pairs(available) do
      missing[name] = nil
    end

    local names = vim.tbl_keys(missing)
    table.sort(names)
    if #names > 0 then
      error(("missing included pack specs: %s"):format(table.concat(names, ", ")))
    end
  end

  return imported
end

function M.normalize(inputs)
  local flattened = {}
  local seen = {}
  for _, input in ipairs(inputs or {}) do
    append_spec(flattened, input, seen)
  end

  local normalized = {}
  for _, input in ipairs(flattened) do
    local repo = input[1]
    if not repo then
      error("pack spec is missing repository at index 1")
    end

    if input.enabled ~= false then
      table.insert(normalized, {
        name = M.spec_name(input),
        source = input.src or M.plugin_source(repo),
        rev = input.rev or input.version or input.branch,
        sha256 = input.sha256 or input.hash,
        dependencies = vim.tbl_map(function(dependency)
          if type(dependency) == "string" then
            return M.plugin_name(dependency)
          end
          return M.spec_name(dependency)
        end, M.as_list(input.dependencies)),
        lazy = input.lazy ~= false
          and (input.cmd ~= nil or input.keys ~= nil or input.event ~= nil or input.lazy == true),
        cmd = input.cmd,
        keys = input.keys,
        event = input.event,
        config = input.config,
        opts = input.opts,
        main = M.main_module_name(input),
      })
    end
  end

  return normalized
end

return M
