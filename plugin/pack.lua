vim.api.nvim_create_user_command("PackStatus", function()
  local loader = require("custom.pack.loader")
  local rows = loader.status()
  local summary = loader.summary()
  local lines = {
    ("loaded %d/%d plugins"):format(summary.loaded, summary.total),
    "",
  }

  if summary.ambient_start > 0 then
    table.insert(lines, ("ambient start packages: %d"):format(summary.ambient_start))
    for _, row in ipairs(summary.ambient_start_packages) do
      table.insert(lines, ("sourced\tstart\t%s\t%s"):format(row.name, row.path))
    end
    table.insert(lines, "")
  end

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
