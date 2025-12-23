return {
  {
    "neovim/nvim-lspconfig",
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
      if vim.o.filetype == "markdown" or vim.o.filetype == "codecompanion" then
        return
      end

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
        lua_ls = true,
        stylua = true,
        rust_analyzer = true,
        svelte = true,
        templ = true,
        taplo = true,
        intelephense = true,

        pyright = true,
        ruff = { manual_install = true },
        -- mojo = { manual_install = true },

        -- Enabled biome formatting, turn off all the other ones generally
        biome = true,
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
        -- denols = true,
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

        -- cssls = {
        --   server_capabilities = {
        --     documentFormattingProvider = false,
        --   },
        -- },

        yamlls = {
          settings = {
            yaml = {
              schemaStore = {
                enable = false,
                url = "",
              },
              -- schemas = require("schemastore").yaml.schemas(),
            },
          },
        },

        ols = { manual_install = true },

        ocamllsp = {
          manual_install = true,
          cmd = { "dune", "tools", "exec", "ocamllsp" },
          -- cmd = { "dune", "exec", "ocamllsp" },
          settings = {
            codelens = { enable = true },
            inlayHints = { enable = true },
            syntaxDocumentation = { enable = true },
          },

          server_capabilities = { semanticTokensProvider = false },
        },

        gleam = {
          manual_install = true,
        },

        clangd = {
          -- cmd = { "clangd", unpack(require("custom.clangd").flags) },
          init_options = { clangdFileStatus = true },
          filetypes = { "c" },
        },
      }

      local servers_to_install = vim.tbl_filter(function(key)
        local t = servers[key]
        if type(t) == "table" then
          return not t.manual_install
        else
          return t
        end
      end, vim.tbl_keys(servers))

      require("mason").setup()
      local ensure_installed = {
        "lua_ls",
        "delve",
      }

      vim.list_extend(ensure_installed, servers_to_install)
      require("mason-tool-installer").setup({ ensure_installed = ensure_installed })

      for name, cfg in pairs(servers) do
        if cfg == true then
          cfg = {}
        end
        local config = vim.tbl_deep_extend("force", { capabilities = capabilities }, cfg)
        vim.lsp.config(name, config)
        vim.lsp.enable(name)
      end

      local disable_semantic_tokens = {
        lua = true,
      }

      vim.api.nvim_create_autocmd("LspAttach", {
        callback = function(args)
          local bufnr = args.buf
          local client = assert(vim.lsp.get_client_by_id(args.data.client_id), "must have valid client")

          local settings = servers[client.name]
          if type(settings) ~= "table" then
            settings = {}
          end

          vim.opt_local.omnifunc = "v:lua.vim.lsp.omnifunc"
          vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = 0, desc = "LSP: Declaration" })
          vim.keymap.set("n", "gT", vim.lsp.buf.type_definition, { buffer = 0, desc = "LSP: Type definition" })
          vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
          end, { buffer = 0, desc = "LSP: Hover documentation" })
          vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, { buffer = 0, desc = "LSP: Code actions" })
          vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, { buffer = 0, desc = "LSP: Rename symbol" })
          vim.keymap.set("n", "<C-h>", function()
            vim.lsp.buf.signature_help({ border = "rounded" })
          end, { buffer = 0, desc = "LSP: Signature help" })
          vim.keymap.set(
            "n",
            "<leader>lf",
            vim.diagnostic.open_float,
            { buffer = 0, desc = "LSP: Open diagnostics float" }
          )
          vim.keymap.set("n", "[d", vim.diagnostic.get_next, { buffer = 0, desc = "Next diagnostic" })
          vim.keymap.set("n", "]d", vim.diagnostic.get_prev, { buffer = 0, desc = "Previous diagnostic" })
          vim.keymap.set("n", "<leader>lws", vim.lsp.buf.workspace_symbol, { buffer = 0, desc = "Workspace symbols" })

          local filetype = vim.bo[bufnr].filetype
          if disable_semantic_tokens[filetype] then
            client.server_capabilities.semanticTokensProvider = nil
          end

          -- Override server capabilities
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
      end, { desc = "Toggle lsp_lines" })
    end,
  },
}
