local colorscheme = "rose-pine-moon"
vim.cmd.colorscheme(colorscheme)

vim.api.nvim_create_user_command("ReloadTheme", function()
  dofile(vim.fn.stdpath("config") .. "/plugin/colors.lua")
end, {})
