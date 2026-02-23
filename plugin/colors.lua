local function reload_fzf_env()
  local cmd = vim.fn.expand("$XDG_CONFIG_HOME/fzf/build-opts.sh")
  -- Force 256-color opts: Neovim uses cterm colors (termguicolors=false)
  local handle = io.popen(cmd .. " --256")
  if not handle then
    return
  end

  local opts = handle:read("*a"):gsub("%s+$", "")
  handle:close()

  vim.fn.setenv("FZF_DEFAULT_OPTS", opts)
end

--- Read palette.json and set vim.g.theme_background to "light" or "dark"
--- based on the luminance of the bg color.
local function detect_background()
  local palette_path = vim.fn.expand("$XDG_CONFIG_HOME/thememanager/palette.json")
  local f = io.open(palette_path, "r")
  if not f then
    return
  end
  local content = f:read("*a")
  f:close()

  local bg_hex = content:match('"bg"%s*:%s*"#?([0-9a-fA-F]+)"')
  if not bg_hex or #bg_hex < 6 then
    return
  end

  local r = tonumber(bg_hex:sub(1, 2), 16)
  local g = tonumber(bg_hex:sub(3, 4), 16)
  local b = tonumber(bg_hex:sub(5, 6), 16)
  -- simple perceived luminance
  local lum = 0.299 * r + 0.587 * g + 0.114 * b
  vim.g.theme_background = lum > 127 and "light" or "dark"
end

vim.api.nvim_create_user_command("ReloadTheme", function()
  reload_fzf_env()
  detect_background()
  vim.cmd("source " .. vim.fn.fnamemodify(vim.env.MYVIMRC, ":h") .. "/plugin/theme.lua")
  vim.api.nvim_exec_autocmds("ColorScheme", { pattern = "custom" })
  vim.cmd("redrawstatus!")
end, {})
