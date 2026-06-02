local M = {}

local ns = vim.api.nvim_create_namespace("custom-fim")
local state = {}

local function lines(text)
  return vim.split(text, "\n", { plain = true })
end

local function virt_lines(extra_lines, hl)
  if #extra_lines == 0 then
    return nil
  end

  return vim.tbl_map(function(line)
    return { { line, hl } }
  end, extra_lines)
end

function M.show(ctx, text, opts)
  opts = opts or {}
  if not ctx or not vim.api.nvim_buf_is_valid(ctx.bufnr) or text == "" then
    return
  end

  local parts = lines(text)
  local first = table.remove(parts, 1) or ""
  vim.api.nvim_buf_clear_namespace(ctx.bufnr, ns, 0, -1)

  if first == "" and #parts == 0 then
    return
  end

  vim.api.nvim_buf_set_extmark(ctx.bufnr, ns, ctx.row, ctx.col, {
    virt_text = first ~= "" and { { first, opts.highlight or "Comment" } } or nil,
    virt_text_win_col = vim.fn.virtcol(".") - 1,
    virt_lines = virt_lines(parts, opts.highlight or "Comment"),
    hl_mode = "combine",
    right_gravity = false,
  })

  state = {
    bufnr = ctx.bufnr,
    text = text,
    ctx = ctx,
  }
end

function M.clear(bufnr)
  bufnr = bufnr or state.bufnr or 0
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  end
  state = {}
end

function M.current()
  if state.bufnr and vim.api.nvim_buf_is_valid(state.bufnr) then
    return state
  end

  return nil
end

function M.namespace()
  return ns
end

return M
