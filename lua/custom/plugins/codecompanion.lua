return {
  {
    "olimorris/codecompanion.nvim",
    opts = {},
    enabled = true,
    cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat" },
    keys = {
      { "<leader>ia", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Actions" },
      { "<leader>it", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Chat Toggle" },
      { "<leader>in", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Chat New" },
      { "<leader>ic", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "CodeCompanion: Chat Add" },
      { "<leader>ig", "<cmd>CodeCompanion /commit<cr>", mode = "n", desc = "CodeCompanion: Generate Git Commit" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "echasnovski/mini.diff",
      {
        "MeanderingProgrammer/render-markdown.nvim",
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
              model = "gemini-flash-lite-latest",
            },
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
                  api_key = require("custom.passloader").get_var("GEMINI_API_KEY"),
                },
              })
            end,
            openai = function()
              return require("codecompanion.adapters").extend("openai", {
                env = {
                  api_key = require("custom.passloader").get_var("OPENAI_API_KEY"),
                },
              })
            end,
          },
        },
        prompt_library = {
          ["Analyze Staged Diff"] = require("custom.codecompanion.templates.git_staged_diff"),
        },
      })

      -- Expand 'cc' into 'CodeCompanion' in the command line
      vim.cmd([[cab cc CodeCompanion]])

      require("custom.codecompanion.codecompanion-spinner").spinner:init()
    end,
  },
}
