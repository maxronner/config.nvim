-- Startup entry: derive &background from the thememanager palette (if present)
-- and activate the `custom` colorscheme. Sourcing colors/custom.lua applies
-- highlights and installs an OptionSet autocmd for live background changes.
local theme = require("custom.theme")
theme.detect_background()
vim.cmd.colorscheme("custom")

-- :ReloadTheme [light|dark]
-- Invoked over IPC by scripts/apply-theme when thememanager swaps the palette.
-- Re-reads palette.json and re-applies highlights so bg-dependent logic
-- (greyscale inversion, contrast guard) picks up the new colors without
-- requiring a manual :colorscheme reload.
vim.api.nvim_create_user_command("ReloadTheme", function(opts)
  theme.reload(opts.args ~= "" and opts.args or nil)
end, {
  nargs = "?",
  complete = function()
    return { "light", "dark" }
  end,
})
