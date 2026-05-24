local M = {}

local snippets = {
  all = {
    hello = "Hello World!",
    curtime = function()
      return os.date("%Y-%m-%d %H:%M:%S")
    end,
    date = function()
      return os.date("%Y-%m-%d")
    end,
    time = function()
      return os.date("%H:%M:%S")
    end,
    mr = "Max Ronner",
    es = "Best regards, Max Ronnner",
  },
  bash = {
    shebang = "#!/usr/bin/env bash\n${1:# description}\n",
  },
  gitcommit = {
    choredeps = "chore(deps): Update Neovim configuration submodule",
  },
  lua = {
    lf = "local ${1:name} = function(${2:args})\n\t$0\nend",
    req = 'local ${1:name} = require "${2:module}"',
  },
  zsh = {
    shebang = "#!/usr/bin/env zsh\n${1:# description}\n",
  },
}

local function snippet_for(filetype, name)
  local filetype_snippets = snippets[filetype]
  return filetype_snippets and filetype_snippets[name] or snippets.all[name]
end

function M.names()
  local names = {}
  local seen = {}

  local function add(group)
    for name in pairs(group or {}) do
      if not seen[name] then
        seen[name] = true
        table.insert(names, name)
      end
    end
  end

  add(snippets.all)
  add(snippets[vim.bo.filetype])
  table.sort(names)
  return names
end

function M.expand(name)
  local body = snippet_for(vim.bo.filetype, name)
  if type(body) == "function" then
    body = body()
  end

  if not body then
    vim.notify("Unknown snippet: " .. name, vim.log.levels.WARN)
    return false
  end

  vim.snippet.expand(body)
  return true
end

return M
