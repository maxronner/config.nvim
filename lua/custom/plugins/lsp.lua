return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      {
        -- `lazydev` configures Lua LSP for your Neovim config, runtime and plugins
        -- used for completion, annotations and signatures of Neovim apis
        "folke/lazydev.nvim",
        ft = "lua",
        opts = {
          library = {
            -- See the configuration section for more details
            -- Load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
          },
        },
      },

      -- Autoformatting and linting
      "stevearc/conform.nvim",

      -- Schema information
      "b0o/SchemaStore.nvim",
    },

    config = function()
      vim.opt.completeopt = { "menuone", "noselect", "popup" }
      if vim.fn.exists("+autocomplete") == 1 then
        vim.opt.autocomplete = true
      end

      vim.keymap.set("n", "<leader>lf", function()
        vim.lsp.buf.format()
      end, { desc = "LSP: Format buffer" })

      vim.keymap.set("n", "<leader>qd", function()
        vim.diagnostic.setqflist()
      end, { desc = "Diagnostics to quickfix" })

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true

      local servers = {
        bashls = true,
        gopls = {
          settings = {
            gopls = {
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                compositeLiteralTypes = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
        lua_ls = {
          server_capabilities = {
            semanticTokensProvider = false,
          },
        },
        marksman = true,
        nixd = true,
        rust_analyzer = true,
        pyright = true,
        ts_ls = {
          root_dir = require("lspconfig").util.root_pattern("package.json"),
          single_file = false,
          server_capabilities = {
            documentFormattingProvider = false,
          },
        },
        vtsls = {
          server_capabilities = {
            documentFormattingProvider = false,
          },
        },
        jsonls = {
          server_capabilities = {
            documentFormattingProvider = false,
          },
          settings = {
            json = {
              validate = { enable = true },
              schemas = require("schemastore").json.schemas(),
            },
          },
        },

        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                enable = false,
                url = "",
              },
            },
          },
        },
      }

      for name, cfg in pairs(servers) do
        if cfg == true then
          cfg = {}
        end
        local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, cfg)
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local opts = { buffer = args.buf }
          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", opts, { desc = desc }))
          end

          if vim.lsp.completion then
            vim.lsp.completion.enable(true, args.data.client_id, args.buf, {
              autotrigger = true,
            })
            map("i", "<C-Space>", vim.lsp.completion.get, "LSP: Complete")
          end

          map("n", "grtl", function()
            local config = vim.diagnostic.config() or {}
            if config.virtual_text then
              vim.diagnostic.config({ virtual_text = false, virtual_lines = true })
            else
              vim.diagnostic.config({ virtual_text = true, virtual_lines = false })
            end
          end, "LSP: Toggle virtual text")
        end,
      })

      require("custom.autoformat").setup()

      vim.diagnostic.config({
        -- update_in_insert = true,
        virtual_text = {
          prefix = "●", -- Or '■', '●', '>>', '⚠️', etc.
          spacing = 2,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          header = "",
          prefix = "",
        },
      })
    end,
  },
}
