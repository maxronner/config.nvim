-- Run a curated set of :checkhealth providers in a predictable way.
-- Intended for --headless CI usage.

vim.o.more = false
vim.o.cmdheight = 999
vim.o.shortmess = vim.o.shortmess .. "FI"

local checks = {
  "nvim",
  "lazy",
  "vim.lsp",
  "nvim-treesitter",
  "mason",
}

local had_error = false

for _, name in ipairs(checks) do
  io.stdout:write(("==> checkhealth %s\n"):format(name))

  local ok, err = pcall(function()
    vim.cmd("silent! checkhealth " .. name)
  end)

  if not ok then
    had_error = true
    io.stderr:write(("checkhealth %s failed: %s\n"):format(name, err))
  end
end

os.exit(had_error and 1 or 0)
