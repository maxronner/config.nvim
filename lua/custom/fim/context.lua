local M = {}

local function trim_start(text, max_chars)
  if #text <= max_chars then
    return text
  end

  return text:sub(#text - max_chars + 1)
end

local function trim_end(text, max_chars)
  if #text <= max_chars then
    return text
  end

  return text:sub(1, max_chars)
end

function M.collect(bufnr, opts)
  bufnr = bufnr and bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  opts = opts or {}

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = math.max(row, 1)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  local before = vim.api.nvim_buf_get_text(bufnr, 0, 0, row - 1, col, {})
  local after = vim.api.nvim_buf_get_text(bufnr, row - 1, col, line_count - 1, -1, {})
  local prefix = trim_start(table.concat(before, "\n"), opts.prefix_chars or 6000)
  local suffix = trim_end(table.concat(after, "\n"), opts.suffix_chars or 3000)

  return {
    bufnr = bufnr,
    row = row - 1,
    col = col,
    prefix = prefix,
    suffix = suffix,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
    filetype = vim.bo[bufnr].filetype,
    filename = vim.api.nvim_buf_get_name(bufnr),
  }
end

return M
