vim.g.mapleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json"

local function system(args)
  local out = vim.fn.system(args)
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to run: " .. table.concat(args, " ") .. "\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

local function locked_lazy_commit()
  local ok, lock = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(lockfile), "\n"))
  end)

  return ok and lock["lazy.nvim"] and lock["lazy.nvim"].commit or nil
end

local lazy_commit = locked_lazy_commit()
if not vim.uv.fs_stat(lazypath) then
  system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
end

if lazy_commit then
  local head_path = lazypath .. "/.git/HEAD"
  local head = vim.uv.fs_stat(head_path) and vim.fn.readfile(head_path)[1]

  if head ~= lazy_commit then
    system({ "git", "-C", lazypath, "checkout", lazy_commit })
  end
end

-- Add lazy to the `runtimepath`, this allows us to `require` it.
vim.opt.rtp:prepend(lazypath)

-- Set up lazy, and load my `lua/custom/plugins/` folder
require("lazy").setup({
  { import = "custom/plugins" },
}, {
  change_detection = {
    notify = false,
  },
})
