local M = {}

local notified_missing = {}

local function web_formatters()
  return { "biome", "prettierd", "prettier", stop_after_first = true }
end

local formatters_by_ft = {
  css = web_formatters(),
  elixir = { "mix" },
  erlang = { "erlfmt", "efmt", stop_after_first = true },
  go = { "gofmt" },
  graphql = web_formatters(),
  html = web_formatters(),
  javascript = web_formatters(),
  javascriptreact = web_formatters(),
  json = web_formatters(),
  jsonc = web_formatters(),
  lua = { "stylua" },
  markdown = web_formatters(),
  python = { "ruff_format", "black", stop_after_first = true },
  rust = { "rustfmt" },
  scss = web_formatters(),
  sh = { "shfmt" },
  typescript = web_formatters(),
  typescriptreact = web_formatters(),
  yaml = { "yamlfmt" },
}

local function configured_formatters(bufnr)
  local filetype = vim.bo[bufnr].filetype
  return formatters_by_ft[filetype]
end

local function formatter_names(formatters)
  local names = {}
  if type(formatters) ~= "table" then
    return names
  end

  for _, formatter in ipairs(formatters) do
    if type(formatter) == "string" then
      names[#names + 1] = formatter
    end
  end

  return names
end

local function has_available_formatter(conform, bufnr, names)
  for _, name in ipairs(names) do
    if conform.get_formatter_info(name, bufnr).available then
      return true
    end
  end

  return false
end

local function notify_missing_once(bufnr, names)
  local filetype = vim.bo[bufnr].filetype
  local key = string.format("%s:%s", filetype, table.concat(names, ","))
  if notified_missing[key] then
    return
  end

  notified_missing[key] = true
  vim.schedule(function()
    vim.notify(
      string.format("Autoformat skipped for %s: no formatter available (%s)", filetype, table.concat(names, ", ")),
      vim.log.levels.WARN,
      { title = "autoformat" }
    )
  end)
end

function M.setup()
  local conform = require("conform")

  conform.setup({
    formatters_by_ft = formatters_by_ft,
    formatters = {
      biome = {
        condition = function(_, ctx)
          return vim.fs.find({ "biome.json", "biome.jsonc" }, { path = ctx.filename, upward = true })[1] ~= nil
        end,
      },
    },
    format_on_save = function(bufnr)
      local formatters = configured_formatters(bufnr)
      if not formatters then
        return nil
      end

      local names = formatter_names(formatters)
      if #names == 0 then
        return nil
      end

      if not has_available_formatter(conform, bufnr, names) then
        notify_missing_once(bufnr, names)
        return nil
      end

      return {
        lsp_format = "never",
        timeout_ms = 500,
      }
    end,
    notify_no_formatters = false,
  })
end

return M
