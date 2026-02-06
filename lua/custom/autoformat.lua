local setup = function()
  local conform = require("conform")
  conform.setup({
    formatters_by_ft = {
      css = { "prettier" },
      elixir = { "mix", "format" },
      erlang = { "mix", "format" },
      go = { "gofmt" },
      graphql = { "prettier" },
      html = { "prettier" },
      javascript = { "prettier" },
      javascriptreact = { "prettier" },
      json = { "prettier" },
      lua = { "stylua" },
      markdown = { "prettier" },
      python = { "black" },
      rust = { "rustfmt" },
      scss = { "prettier" },
      sh = { "shfmt" },
      typescript = { "prettier" },
      typescriptreact = { "prettier" },
      yaml = { "prettier" },
    },
  })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("custom-conform", { clear = true }),
    callback = function(args)
      require("conform").format({
        bufnr = args.buf,
        lsp_fallback = true,
        quiet = true,
      })
    end,
  })
end

setup()

return { setup = setup }
