local data = assert(vim.fn.stdpath "data") --[[@as string]]
local telescope = require "telescope"
local builtin = require "telescope.builtin"

telescope.setup({
  defaults = {
    file_ignore_patterns = { "%.DS_Store", "node_modules" },
    history = {
      path = vim.fs.joinpath(data, "telescope_history.sqlite3"),
      limit = 100,
    },
    mappings = {
      i = {
        ["<C-q>"] = require('telescope.actions').delete_buffer,
      },
      n = {
        ["<C-q>"] = require('telescope.actions').delete_buffer,
      },
    }
  },
  extensions = {
    wrap_results = true,

    fzf = {
      fuzzy = true,                   -- false will only do exact matching
      override_generic_sorter = true, -- override the generic sorter
      override_file_sorter = true,    -- override the file sorter
      case_mode = "smart_case",       -- or "ignore_case" or "respect_case"
    },
    ["ui-select"] = {
      require("telescope.themes").get_dropdown {},
    },
    frecency = {
      auto_validate = false,
      matcher = "fuzzy",
      path_display = { "filename_first" },
      ignore_patterns = { "*/.git", "*/.git/*", "*/.DS_Store" },
      bootstrap = true,
      default_workspace = "CWD",
      hide_current_buffer = true,
      prompt_title = "Find Files (frecency)",
    }
  },
})

pcall(telescope.load_extension, "fzf")
pcall(telescope.load_extension, "smart_history")
pcall(telescope.load_extension, "ui-select")
pcall(telescope.load_extension, "frecency")

local frecency = telescope.extensions.frecency
vim.keymap.set("n", "<leader>/", builtin.current_buffer_fuzzy_find, { desc = "Telescope: Fuzzy find in current buffer" })
vim.keymap.set("n", "<leader>fp", builtin.find_files, { desc = "Telescope: Find files" })
vim.keymap.set("n", "<leader>fa", function()
  builtin.find_files({ hidden = true, prompt_title = "Find files (all)" })
end, { desc = "Telescope: Find files (hidden)" })
vim.keymap.set("n", "<leader>fo", builtin.oldfiles, { desc = "Telescope: Old files" })
vim.keymap.set("n", "<leader>ff", frecency.frecency, { desc = "Telescope: Find frequent files" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope: Buffers" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Telescope: Live grep" })
vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Telescope: Grep selection" })

vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Telescope: Keymaps" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope: Help tags" })
vim.keymap.set("n", "<leader>:", builtin.command_history, { desc = "Telescope: Command history" })
vim.keymap.set("n", "<leader>fH", builtin.search_history, { desc = "Telescope: Search history" })

vim.keymap.set("n", "<leader>vv", function()
  builtin.find_files { cwd = vim.fn.stdpath "config", prompt_title = "Nvim Config" }
end, { desc = "Telescope: Find files in config" })
vim.keymap.set("n", "<leader>vl", function()
  builtin.find_files { cwd = vim.fn.stdpath "data" .. "/lazy", prompt_title = "Nvim Plugins" }
end, { desc = "Telescope: Find files in plugins" })

vim.keymap.set("n", "<leader>fi", builtin.git_files, { desc = "Telescope: Git files" })
vim.keymap.set('n', '<leader>fc', builtin.git_branches, { desc = 'Telescope: Git Branch Checkout' })
vim.keymap.set("n", "<leader>fm", builtin.git_status, { desc = "Telescope: Git status" })

vim.keymap.set("n", "<leader>fd", builtin.lsp_definitions, { buffer = 0, desc = "Telescope: LSP Definitions" })
vim.keymap.set("n", "<leader>fr", builtin.lsp_references, { buffer = 0, desc = "Telescope: LSP References" })
vim.keymap.set("n", "<leader>ls", builtin.lsp_document_symbols,
  { buffer = 0, desc = "Telescope: LSP Document symbols" })
