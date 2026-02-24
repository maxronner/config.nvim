-- Initial theme application on startup.
-- Background has already been set by plugin/colors.lua (loads first
-- alphabetically). The canonical re-entry point for colorscheme reloads
-- and background changes is colors/custom.lua.
require("custom.theme").apply()
