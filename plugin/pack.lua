vim.api.nvim_create_user_command("PackStatus", function()
  local loader = require("custom.pack.loader")
  local rows = loader.status()
  local counts = loader.counts()
  local lines = {
    ("loaded %d/%d plugins"):format(counts.loaded, counts.total),
    "",
  }

  for _, row in ipairs(rows) do
    local state = row.loaded and "loaded" or "pending"
    local mode = row.lazy and "lazy" or "start"
    table.insert(lines, ("%s\t%s\t%s"):format(state, mode, row.name))
  end

  vim.cmd.new()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.filetype = "packstatus"
  vim.api.nvim_buf_set_name(0, "PackStatus")
  vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end, { desc = "Show pack plugin status" })
