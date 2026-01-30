return {
  {
    "neovim/nvim-lspconfig",
    event = "BufReadPre",
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

      -- Tooling package management
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",

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
          manual_install = true,
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
        rust_analyzer = true,
        intelephense = true,
        pyright = true,

        -- ts_ls = {
        --   root_dir = require("lspconfig").util.root_pattern "package.json",
        --   single_file = false,
        --   server_capabilities = {
        --     documentFormattingProvider = false,
        --   },
        -- },
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

        clangd = {
          init_options = { clangdFileStatus = true },
          filetypes = { "c" },
        },
      }

      -- formatters/linters/debuggers/etc for mason-tool-installer
      local tools = {
        "stylua",
        "ruff",
        "delve",
      }

      local ensure_installed = vim.tbl_filter(function(key)
        local t = servers[key]
        if type(t) == "table" then
          return not t.manual_install
        else
          return t
        end
      end, vim.tbl_keys(servers))

      require("mason").setup()
      require("mason-tool-installer").setup({
        ensure_installed = vim.list_extend(ensure_installed, tools),
      })

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
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id), "must have valid client")
          vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"

          local map = function(mode, key, func, opts)
            vim.keymap.set(mode, key, func, vim.tbl_extend("force", { buffer = 0, desc = "LSP: " .. key }, opts or {}))
          end
          map("n", "gD", vim.lsp.buf.declaration, { desc = "LSP: Declaration" })
          map("n", "gT", vim.lsp.buf.type_definition, { desc = "LSP: Type definition" })
          map("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
          end, { desc = "LSP: Hover documentation" })
          map("n", "<leader>la", vim.lsp.buf.code_action, { desc = "LSP: Code actions" })
          map("n", "<leader>lr", vim.lsp.buf.rename, { desc = "LSP: Rename symbol" })
          map("n", "<C-h>", function()
            vim.lsp.buf.signature_help({ border = "rounded" })
          end, { desc = "LSP: Signature help" })
          map("n", "<leader>lf", vim.diagnostic.open_float, { desc = "LSP: Open diagnostics float" })
          map("n", "<leader>lws", vim.lsp.buf.workspace_symbol, { desc = "Workspace symbols" })

          local settings = servers[client.name]
          if type(settings) ~= "table" then
            settings = {}
          end
          if settings.server_capabilities then
            for k, v in pairs(settings.server_capabilities) do
              if v == vim.NIL then
                ---@diagnostic disable-next-line: cast-local-type
                v = nil
              end

              client.server_capabilities[k] = v
            end
          end
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

      vim.keymap.set("", "<leader>ll", function()
        local config = vim.diagnostic.config() or {}
        if config.virtual_text then
          vim.diagnostic.config({ virtual_text = false, virtual_lines = true })
        else
          vim.diagnostic.config({ virtual_text = true, virtual_lines = false })
        end
      end, { desc = "LSP: Toggle virtual text" })
    end,
  },
}
