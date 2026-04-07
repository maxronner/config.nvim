return {
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
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

      -- LSP progress messages
      {
        "j-hui/fidget.nvim",
        opts = {
          notification = {
            window = {
              winblend = 0,
              y_padding = 1,
            },
          },
        },
      },
    },

    config = function()
      local capabilities = nil
      if pcall(require, "cmp_nvim_lsp") then
        capabilities = require("cmp_nvim_lsp").default_capabilities()
      end

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
          settings = {
            Lua = {
              workspace = {
                checkThirdParty = false,
                library = {
                  vim.env.VIMRUNTIME,
                  { path = "${3rd}/luv/library", words = { "vim%.uv" } },
                },
              },
            },
          },
        },
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

          map({ "n", "x" }, "gra", vim.lsp.buf.code_action, "LSP: Code action")
          map("n", "grn", vim.lsp.buf.rename, "LSP: Rename")
          map("n", "gri", vim.lsp.buf.implementation, "LSP: Implementation")
          map("n", "grr", vim.lsp.buf.references, "LSP: References")
          map("n", "grt", vim.lsp.buf.type_definition, "LSP: Type definition")
          map("n", "gO", vim.lsp.buf.document_symbol, "LSP: Document symbols")
          map("n", "grx", vim.lsp.codelens.run, "LSP: CodeLens")
          map("i", "<C-S>", vim.lsp.buf.signature_help, "LSP: Signature help")

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
