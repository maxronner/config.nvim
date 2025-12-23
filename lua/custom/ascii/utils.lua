local M = {}

M.lazy_load = function(module, path, modules)
  setmetatable(module, {
    __index = function(t, key)
      if vim.tbl_contains(modules, key) then
        local ok, mod = pcall(require, path .. key)
        if not ok then
          vim.notify("Failed to load module: " .. path .. key, vim.log.levels.WARN)
          return nil
        end
        t[key] = mod
        return mod
      end
      return nil
    end,
  })
end

-- Directory of caller
function M.current_dir()
  local src = debug.getinfo(2, "S").source:sub(2)
  return vim.fn.fnamemodify(src, ":h") .. "/"
end

-- Discover every .lua file inside every subdirectory.
-- Returns entries like: "creatures.spiritual" or "planets.mars"
function M.modules_in_subdirs()
  local base = M.current_dir()
  local dirs = vim.fn.readdir(base)
  local out = {}

  for _, dir in ipairs(dirs) do
    local full = base .. dir
    if vim.fn.isdirectory(full) == 1 then
      local files = vim.fn.readdir(full)
      for _, f in ipairs(files) do
        if f:sub(-4) == ".lua" and f ~= "init.lua" then
          table.insert(out, dir .. "." .. f:sub(1, -5))
        end
      end
    end
  end

  return out
end

return M
