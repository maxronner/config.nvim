local setup = function()
  local conform = require("conform")
  conform.setup({
    formatters_by_ft = {
      lua = { "stylua" },
      elixir = { "mix", "format" },
      erlang = { "mix", "format" },
      javascript = { "prettier" },
      typescript = { "prettier" },
      css = { "prettier" },
      scss = { "prettier" },
      html = { "prettier" },
      json = { "prettier" },
      yaml = { "prettier" },
      markdown = { "prettier" },
      sh = { "shfmt" },
      rust = { "rustfmt" },
      python = { "black" },
      javascriptreact = { "prettier" },
      typescriptreact = { "prettier" },
      graphql = { "prettier" },
    },
  })
  vim.api.nvim_create_autocmd("BufWritePre", {
    group = vim.api.nvim_create_augroup("custom-conform", { clear = true }),
    callback = function(args)
      require("conform").format {
        bufnr = args.buf,
        lsp_fallback = true,
        quiet = true,
      }
    end,
  })
end

setup()

return { setup = setup }
