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

-- Buffers
vim.keymap.set("n", "<leader>/", fzf.lines, { desc = "Fzf: Fuzzy find in current buffer" })
vim.keymap.set("n", "<leader>fb", fzf.buffers, { desc = "Fzf: Buffers" })

-- Files
vim.keymap.set("n", "<leader>fP", function()
  fzf.files({ no_ignore = true })
end, { desc = "Fzf: Find files (all)" })
vim.keymap.set("n", "<leader>fp", function()
  fzf.files({ hidden = false })
end, { desc = "Fzf: Find files (no hidden, no ignored)" })
vim.keymap.set("n", "<leader>fo", fzf.oldfiles, { desc = "Fzf: Find old files" })
vim.keymap.set("n", "<leader>fi", fzf.git_files, { desc = "Fzf: Git files" })

-- Grep
vim.keymap.set("n", "<leader>fl", fzf.live_grep, { desc = "Fzf: Live grep" })
vim.keymap.set("n", "<leader>fg", fzf.grep, { desc = "Fzf: Grep" })
vim.keymap.set("x", "<leader>fw", fzf.grep_visual, { desc = "Fzf: Grep selection" })
vim.keymap.set("n", "<leader>fw", fzf.grep_cword, { desc = "Fzf: Grep word under cursor" })

-- Git
vim.keymap.set("n", "<leader>fc", fzf.git_branches, { desc = "Fzf: Git branch checkout" })
vim.keymap.set("n", "<leader>fm", fzf.git_status, { desc = "Fzf: Git status" })

-- History / help
vim.keymap.set("n", "<leader>:", fzf.command_history, { desc = "Fzf: Command history" })
vim.keymap.set("n", "<leader>fH", fzf.search_history, { desc = "Fzf: Search history" })
vim.keymap.set("n", "<leader>fh", fzf.helptags, { desc = "Fzf: Help tags" })
vim.keymap.set("n", "<leader>fk", fzf.keymaps, { desc = "Fzf: Keymaps" })
vim.keymap.set("n", "<leader>fO", fzf.nvim_options, { desc = "Fzf: Nvim options" })

-- Neovim directories
vim.keymap.set("n", "<leader>vv", function()
  fzf.files({ cwd = vim.fn.stdpath("config") })
end, { desc = "Fzf: Find files in Neovim config" })

vim.keymap.set("n", "<leader>vl", function()
  fzf.files({ cwd = vim.fn.stdpath("data") .. "/lazy" })
end, { desc = "Fzf: Find files in plugins" })

vim.keymap.set("n", "<leader>fd", fzf.lsp_definitions, { desc = "Fzf: LSP Definitions" })
vim.keymap.set("n", "<leader>fr", fzf.lsp_references, { desc = "Fzf: LSP References" })
vim.keymap.set("n", "<leader>ls", fzf.lsp_document_symbols, { desc = "Fzf: LSP Document Symbols" })
