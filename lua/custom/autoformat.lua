local M = {}

local notified_missing = {}

local web_formatters = { "biome", "prettierd", "prettier", stop_after_first = true }

local FORMATTERS_BY_FT = {
  css = web_formatters,
  elixir = { "mix" },
  erlang = { "erlfmt", "efmt", stop_after_first = true },
  go = { "gofmt" },
  graphql = web_formatters,
  html = web_formatters,
  javascript = web_formatters,
  javascriptreact = web_formatters,
  json = web_formatters,
  jsonc = { "prettier_jsonc" },
  lua = { "stylua" },
  markdown = web_formatters,
  python = { "ruff_format", "black", stop_after_first = true },
  rust = { "rustfmt" },
  scss = web_formatters,
  sh = { "shfmt" },
  typescript = web_formatters,
  typescriptreact = web_formatters,
  yaml = { "yamlfmt" },
}

local function get_formatter_names(bufnr)
  local ft = vim.bo[bufnr].filetype
  local formatters = FORMATTERS_BY_FT[ft]

  if type(formatters) ~= "table" then
    return nil
  end

  local names = {}
  for _, formatter in ipairs(formatters) do
    if type(formatter) == "string" then
      names[#names + 1] = formatter
    end
  end

  return #names > 0 and names or nil
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
  local ft = vim.bo[bufnr].filetype
  local key = ("%s:%s"):format(ft, table.concat(names, ","))

  if notified_missing[key] then
    return
  end

  notified_missing[key] = true

  vim.schedule(function()
    vim.notify(
      ("Autoformat skipped for %s: no formatter available (%s)"):format(ft, table.concat(names, ", ")),
      vim.log.levels.WARN,
      { title = "autoformat" }
    )
  end)
end

local function biome_config_exists(filename)
  return vim.fs.find({ "biome.json", "biome.jsonc" }, {
    path = filename,
    upward = true,
  })[1] ~= nil
end

local function format_on_save(conform, bufnr)
  local names = get_formatter_names(bufnr)
  if not names then
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
end

function M.setup()
  local conform = require("conform")

  conform.setup({
    formatters_by_ft = FORMATTERS_BY_FT,
    formatters = {
      biome = {
        condition = function(_, ctx)
          return biome_config_exists(ctx.filename)
        end,
      },
      prettier_jsonc = {
        inherit = false,
        command = "prettier",
        args = {
          "--stdin-filepath",
          "$FILENAME",
          "--trailing-comma",
          "none",
        },
        stdin = true,
      },
    },
    format_on_save = function(bufnr)
      return format_on_save(conform, bufnr)
    end,
    notify_no_formatters = false,
  })
end

return M
