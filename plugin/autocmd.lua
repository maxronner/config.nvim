vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

vim.api.nvim_create_autocmd("BufWritePre", {
  desc = "Remove trailing whitespace",
  pattern = "*",
  callback = function()
    local buf = vim.api.nvim_get_current_buf()
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    local changed = false

    for i, line in ipairs(lines) do
      local cleaned = line:gsub("%s+$", "")
      if cleaned ~= line then
        lines[i] = cleaned
        changed = true
      end
    end

    if changed then
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    end
  end,
})
