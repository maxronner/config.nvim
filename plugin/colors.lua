local colorscheme = "rose-pine-moon"
vim.cmd.colorscheme(colorscheme)

local function reload_fzf_env()
  local cmd = vim.fn.expand("$XDG_CONFIG_HOME/fzf/build-opts.sh")
  local handle = io.popen(cmd)
  if not handle then
    return
  end

  local opts = handle:read("*a"):gsub("%s+$", "")
  handle:close()

  vim.fn.setenv("FZF_DEFAULT_OPTS", opts)
end

vim.api.nvim_create_user_command("ReloadTheme", function()
  dofile(vim.fn.stdpath("config") .. "/plugin/colors.lua")
  reload_fzf_env()
end, {})
