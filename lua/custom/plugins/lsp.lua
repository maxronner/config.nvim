return {
  {
    "b0o/SchemaStore.nvim",
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

      local js_like_filetypes = {
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
      }

      local function node_command(name)
        return function(dispatchers, config)
          local cmd = name
          if (config or {}).root_dir then
            local local_cmd = vim.fs.joinpath(config.root_dir, "node_modules/.bin", name)
            if vim.fn.executable(local_cmd) == 1 then
              cmd = local_cmd
            end
          end

          return vim.lsp.rpc.start({ cmd, "--stdio" }, dispatchers)
        end
      end

      local function ts_root(bufnr, on_dir)
        local project_root = vim.fs.root(bufnr, "package.json")
        if project_root then
          on_dir(project_root)
        end
      end

      local disable_lsp_format = {
        jsonls = true,
        ts_ls = true,
        vtsls = true,
      }

      local servers = {
        bashls = {
          cmd = { "bash-language-server", "start" },
          filetypes = { "bash", "sh" },
          root_markers = { ".git" },
          settings = {
            bashIde = {
              globPattern = vim.env.GLOB_PATTERN or "*@(.sh|.inc|.bash|.command)",
            },
          },
        },
        gopls = {
          cmd = { "gopls" },
          filetypes = { "go", "gomod", "gowork", "gotmpl" },
          root_markers = { "go.work", "go.mod", ".git" },
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
          cmd = { "lua-language-server" },
          filetypes = { "lua" },
          root_markers = {
            { ".luarc.json", ".luarc.jsonc", ".emmyrc.json" },
            { ".luacheckrc", ".stylua.toml", "stylua.toml", "selene.toml", "selene.yml" },
            { ".git" },
          },
          settings = {
            Lua = {
              codeLens = { enable = true },
              hint = { enable = true, semicolon = "Disable" },
            },
          },
        },
        marksman = {
          cmd = { "marksman", "server" },
          filetypes = { "markdown", "markdown.mdx" },
          root_markers = { ".marksman.toml", ".git" },
        },
        nixd = {
          cmd = { "nixd" },
          filetypes = { "nix" },
          root_markers = { "flake.nix", ".git" },
        },
        rust_analyzer = {
          cmd = { "rust-analyzer" },
          filetypes = { "rust" },
          root_markers = { "Cargo.toml", "rust-project.json", ".git" },
        },
        pyright = {
          cmd = { "pyright-langserver", "--stdio" },
          filetypes = { "python" },
          root_markers = {
            "pyrightconfig.json",
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
            ".git",
          },
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                useLibraryCodeForTypes = true,
                diagnosticMode = "openFilesOnly",
              },
            },
          },
        },
        ts_ls = {
          cmd = node_command("typescript-language-server"),
          filetypes = js_like_filetypes,
          root_dir = ts_root,
          init_options = { hostInfo = "neovim" },
        },
        vtsls = {
          cmd = { "vtsls", "--stdio" },
          filetypes = js_like_filetypes,
          root_dir = ts_root,
          init_options = { hostInfo = "neovim" },
        },
        jsonls = {
          cmd = node_command("vscode-json-language-server"),
          filetypes = { "json", "jsonc" },
          root_markers = { ".git" },
          init_options = {
            provideFormatter = true,
          },
          settings = {
            json = {
              validate = { enable = true },
              schemas = require("schemastore").json.schemas(),
            },
          },
        },

        yamlls = {
          cmd = node_command("yaml-language-server"),
          filetypes = { "yaml", "yaml.docker-compose", "yaml.gitlab", "yaml.helm-values" },
          root_markers = { ".git" },
          settings = {
            redhat = { telemetry = { enabled = false } },
            yaml = {
              format = { enable = true },
              schemaStore = {
                enable = false,
                url = "",
              },
            },
          },
          on_init = function(client)
            client.server_capabilities.documentFormattingProvider = true
          end,
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
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client then
            if client.name == "lua_ls" then
              client.server_capabilities.semanticTokensProvider = nil
            end
            if disable_lsp_format[client.name] then
              client.server_capabilities.documentFormattingProvider = false
            end
          end

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
