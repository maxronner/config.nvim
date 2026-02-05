local fzf = require("fzf-lua")
local actions = require("fzf-lua.actions")

fzf.setup({
  winopts = {
    height = 0.85,
    width = 0.85,
    border = "rounded",
  },

  files = {
    git_icons = true,
    file_icons = true,
    actions = {
      ["ctrl-q"] = {
        fn = actions.file_sel_to_qf,
      },
    },
  },

  grep = {
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096",
    actions = {
      ["ctrl-q"] = {
        fn = actions.file_sel_to_qf,
      },
    },
  },
})

fzf.register_ui_select()
