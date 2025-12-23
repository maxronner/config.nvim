local function open_terminal_bottom_split()
  local total_lines = vim.o.lines
  local term_height_ratio = 5 -- configurable ratio
  local term_height = math.floor(total_lines / term_height_ratio)

  vim.cmd.new()
  vim.cmd.term()
  vim.cmd.wincmd("J")
  vim.api.nvim_win_set_height(0, term_height)
  vim.cmd.startinsert()
end

vim.api.nvim_create_autocmd("TermOpen", {
  callback = function()
    vim.opt_local.winbar = ""
  end,
})

vim.keymap.set("n", "<leader>zz", function()
  if vim.fn.executable("tmux-scratch") == 1 then
    vim.cmd("silent !tmux-scratch -P")
  else
    open_terminal_bottom_split()
    vim.notify("tmux-scratch not found, opening regular terminal.", vim.log.levels.WARN)
  end
end, { desc = "Open/Swap tmux pane or open terminal" })
