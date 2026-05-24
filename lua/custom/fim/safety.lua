local config = require("custom.fim.config")

local M = {}

local function expand_pattern(pattern)
  local expanded = pattern:gsub("^~", vim.fn.expand("~"), 1)
  return vim.fn.glob2regpat(expanded)
end

local function absolute_path(path)
  if not path or path == "" then
    return ""
  end

  return vim.fn.fnamemodify(path, ":p")
end

local function path_reason(path, opts)
  local abs = absolute_path(path)
  if abs == "" then
    return nil
  end

  for _, pattern in ipairs(opts.blocked_path_patterns or {}) do
    if vim.fn.match(abs, expand_pattern(pattern)) >= 0 then
      return "blocked path: " .. pattern
    end
  end
end

local function filetype_reason(bufnr, opts)
  local filetype = vim.bo[bufnr].filetype
  if filetype == "" then
    return nil
  end

  for _, blocked in ipairs(opts.blocked_filetypes or {}) do
    if filetype == blocked then
      return "blocked filetype: " .. blocked
    end
  end
end

local function buftype_reason(bufnr)
  local buftype = vim.bo[bufnr].buftype
  if buftype ~= "" then
    return "blocked buftype: " .. buftype
  end
end

local function raw_reason(bufnr, path, opts)
  bufnr = bufnr and bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  opts = opts or config.options

  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "invalid buffer"
  end

  return buftype_reason(bufnr)
    or path_reason(path or vim.api.nvim_buf_get_name(bufnr), opts)
    or filetype_reason(bufnr, opts)
end

function M.reason(bufnr, path, opts)
  bufnr = bufnr and bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return "invalid buffer"
  end

  return vim.b[bufnr].custom_fim_blocked or raw_reason(bufnr, path, opts)
end

function M.mark(bufnr, path, opts)
  bufnr = bufnr and bufnr ~= 0 and bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end

  local reason = raw_reason(bufnr, path, opts)
  vim.b[bufnr].custom_fim_blocked = reason
  return reason
end

return M
