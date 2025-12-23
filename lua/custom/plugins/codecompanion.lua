return {
  {
    "olimorris/codecompanion.nvim",
    opts = {
    },
    enabled = true,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.diff",
      {
        'MeanderingProgrammer/render-markdown.nvim',
        opts = {
          file_types = { "markdown", "codecompanion" },
        },
        ft = { "markdown", "codecompanion" },
      },
    },
    config = function()
      require("codecompanion").setup({
        interactions = {
          chat = {
            adapter = {
              name = "gemini",
              model = "gemini-flash-latest",
            }
          },
          inline = {
            adapter = "gemini",
          },
          cmd = {
            adapter = "gemini",
          },
        },
        adapters = {
          http = {
            gemini = function()
              return require("codecompanion.adapters").extend("gemini", {
                env = {
                  api_key = require("custom.passloader").get_var("GEMINI_API_KEY")
                },
              })
            end,
            openai = function()
              return require("codecompanion.adapters").extend("openai", {
                env = {
                  api_key = require("custom.passloader").get_var("OPENAI_API_KEY")
                }
              })
            end
          }
        }
      })
      vim.keymap.set({ "n", "v" }, "<leader>ia", "<cmd>CodeCompanionActions<cr>",
        { noremap = true, silent = true, desc = "CodeCompanion: Actions" })
      vim.keymap.set({ "n", "v" }, "<leader>it", "<cmd>CodeCompanionChat Toggle<cr>",
        { noremap = true, silent = true, desc = "CodeCompanion: Chat Toggle" })
      vim.keymap.set({ "n", "v" }, "<leader>in", "<cmd>CodeCompanionChat<cr>",
        { noremap = true, silent = true, desc = "CodeCompanion: Chat New" })
      vim.keymap.set("v", "<leader>ic", "<cmd>CodeCompanionChat Add<cr>",
        { noremap = true, silent = true, desc = "CodeCompanion: Chat Add" })

      vim.keymap.set("n", "<leader>ig", ":CodeCompanion /commit<CR>",
        { noremap = true, silent = true, desc = "CodeCompanion: Generate Git Commit" })

      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])

      require("custom.codecompanion-spinner").spinner:init()
    end,
  },
}
