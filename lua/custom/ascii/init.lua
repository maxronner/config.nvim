local utils = require("custom.ascii.utils")

local M = {}

-- Create M.art table, which will be the entry point for ASCII art categories
M.art = {}

-- Get the list of submodule names (e.g., "text", "dos_rebel")
local category_module_names = utils.modules_in_subdirs()

-- Make M.art lazy-load its submodules (e.g., M.art.text)
-- Accessing M.art.text will now automatically `require("custom.ascii.text")`
utils.lazy_load(M.art, "custom.ascii.", category_module_names)

-- Store the list of available category names for iteration (e.g., in get_random_global)
M.art.categories = category_module_names

-- Seed RNG once at module load (improves randomness and avoids repeated seeding)
math.randomseed(vim.uv.hrtime())

-- Simple setup function for lazy.nvim
M.setup = function()
  return M
end

-- shallow print of category names (modules)
M.print_category = function()
  vim.print("Available ASCII art categories (modules):")
  vim.print(M.art.categories)
end

M.get_random = function(category, subcategory)
  -- Accessing M.art[category] will trigger lazy_load if the module hasn't been loaded yet
  local category_module = M.art[category]
  if not category_module then
    vim.notify("Category not found or failed to load: " .. category, vim.log.levels.WARN)
    return nil
  end

  local pieces = category_module[subcategory]
  if not pieces then
    vim.notify(
      "Subcategory '" .. subcategory .. "' not found in category '" .. category .. "'",
      vim.log.levels.WARN
    )
    return nil
  end

  return pieces
end

M.get_random_global = function()
  -- The math.randomseed is already called once at module load, no need to re-seed here.
  -- Removing: math.randomseed(os.time() + math.random(1, 1000))

  local available_categories = M.art.categories
  if #available_categories == 0 then
    vim.notify("No ASCII art categories found.", vim.log.levels.WARN)
    return nil
  end

  local category_name = available_categories[math.random(1, #available_categories)]

  -- Accessing M.art[category_name] will trigger lazy_load
  local category_module = M.art[category_name]
  if not category_module then
    -- This case should ideally be caught by utils.lazy_load's notification,
    -- but added for extra robustness.
    vim.notify("Failed to load module for random category: " .. category_name, vim.log.levels.ERROR)
    return nil
  end

  -- Get only keys that represent ASCII art (tables of lines)
  local subcategories = {}
  for k, v in pairs(category_module) do
    if type(v) == "table" then
      table.insert(subcategories, k)
    end
  end

  if #subcategories == 0 then
    vim.notify("No ASCII art pieces found in category: " .. category_name, vim.log.levels.WARN)
    return nil
  end

  local subcategory_name = subcategories[math.random(1, #subcategories)]
  return M.get_random(category_name, subcategory_name)
end

return M
