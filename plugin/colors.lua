-- Detect whether the current thememanager palette has a light or dark
-- background and prime vim.o.background accordingly before the theme loads.
-- Only runs when palette.json is present (thememanager environment).
-- In all other environments vim.o.background keeps its default ("dark") or
-- whatever the user has set manually.
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
  local lum = 0.299 * r + 0.587 * g + 0.114 * b
  vim.o.background = lum > 127 and "light" or "dark"
end

detect_background()

