-- Canonical colorscheme entry point.
-- Re-sourced by Neovim whenever `colorscheme custom` is run or when
-- `background` changes while this colorscheme is active.

require("custom.theme").apply()

-- Re-apply the theme whenever :set background= changes, so grey() picks up
-- the new direction without needing a full colorscheme reload.
vim.api.nvim_create_autocmd("OptionSet", {
  pattern = "background",
  once = false,
  callback = function()
    require("custom.theme").apply()
  end,
})
