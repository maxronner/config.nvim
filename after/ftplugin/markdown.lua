local set = vim.opt_local

set.colorcolumn = "0"
set.wrap = true
set.linebreak = true
set.breakindent = true
set.spell = true
set.spelllang = "en,sv"

if require("zk.util").notebook_root(vim.fn.expand("%:p")) ~= nil then
  local map = vim.keymap.set
  local opts = { noremap = true, silent = false, buffer = 0 }
  local current_dir = vim.fn.expand("%:p:h")

  -- Open the link under cursor (LSP definition)
  map("n", "<CR>", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Open the link under cursor" }))

  -- Create a new note in current directory, prompting for title
  map("n", "<leader>zn", function()
    local title = vim.fn.input("Title: ")
    vim.cmd(string.format("ZkNew { dir = '%s', title = '%s' }", current_dir, title))
  end, vim.tbl_extend("force", opts, { desc = "New note in current dir" }))

  map(
    "v",
    "<leader>znt",
    string.format(":'<,'>ZkNewFromTitleSelection { dir = '%s' }<CR>", current_dir),
    vim.tbl_extend("force", opts, { desc = "New note from title selection" })
  )

  map(
    "v",
    "<leader>znc",
    string.format(":'<,'>ZkNewFromContentSelection { dir = '%s', title = vim.fn.input('Title: ') }<CR>", current_dir),
    vim.tbl_extend("force", opts, { desc = "New note from content selection" })
  )

  -- Open notes linking to current buffer (backlinks)
  map("n", "<leader>zb", "<Cmd>ZkBacklinks<CR>", vim.tbl_extend("force", opts, { desc = "Show backlinks" }))

  -- Open notes linked by current buffer (links)
  map("n", "<leader>zl", "<Cmd>ZkLinks<CR>", vim.tbl_extend("force", opts, { desc = "Show links" }))

  -- Preview linked note (LSP hover)
  map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover info" }))
end
