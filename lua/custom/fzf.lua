local fzf = require("fzf-lua")
local actions = require("fzf-lua.actions")

local fd_excludes = table.concat({
  "--exclude",
  ".git",
  "--exclude",
  "node_modules",
  "--exclude",
  "dist",
  "--exclude",
  "build",
}, " ")

local rg_excludes = table.concat({
  "--glob=!**/.git/**",
  "--glob=!**/node_modules/**",
  "--glob=!**/dist/**",
  "--glob=!**/build/**",
}, " ")

fzf.setup({
  winopts = {
    height = 0.85,
    width = 0.85,
    border = "rounded",
  },

  files = {
    git_icons = true,
    file_icons = true,
    fd_opts = fzf.defaults.files.fd_opts .. " " .. fd_excludes,
    actions = {
      ["ctrl-q"] = {
        fn = actions.file_sel_to_qf,
      },
    },
  },

  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096 " .. rg_excludes,
    actions = {
      ["ctrl-q"] = {
        fn = actions.file_sel_to_qf,
      },
    },
  },
})

fzf.register_ui_select()
