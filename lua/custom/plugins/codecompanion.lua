return {
  {
    "olimorris/codecompanion.nvim",
    cmd = { "CodeCompanion", "CodeCompanionActions", "CodeCompanionChat" },
    keys = {
      { "<leader>ir", "<cmd>CodeCompanion<cr>", mode = { "n", "v" }, desc = "CodeCompanion: New" },
      { "<leader>ia", "<cmd>CodeCompanionActions<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Actions" },
      { "<leader>it", "<cmd>CodeCompanionChat Toggle<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Chat Toggle" },
      { "<leader>in", "<cmd>CodeCompanionChat<cr>", mode = { "n", "v" }, desc = "CodeCompanion: Chat New" },
      { "<leader>ic", "<cmd>CodeCompanionChat Add<cr>", mode = "v", desc = "CodeCompanion: Chat Add" },
      { "<leader>ig", "<cmd>CodeCompanion /gitcommit<cr>", mode = "n", desc = "CodeCompanion: Analyze Staged Diff" },
      { "<leader>id", "<cmd>CodeCompanion /diffreview<cr>", mode = "n", desc = "CodeCompanion: Review Diff" },
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
    opts = {
      interactions = {
        chat = {
          adapter = "anthropic",
        },
        inline = {
          adapter = "anthropic",
        },
        cmd = {
          adapter = "anthropic",
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
          anthropic = function()
            return require("codecompanion.adapters").extend("anthropic", {
              env = {
                api_key = require("custom.passloader").get_var("ANTHROPIC_API_KEY"),
              },
            })
          end,
        },
      },
      prompt_library = {
        ["Analyze Staged Diff"] = require("custom.codecompanion.templates.git_staged_diff"),
        ["Generate Conventional Commit Message"] = require("custom.codecompanion.templates.gitcommit"),
      },
    },
    init = function()
      vim.cmd([[cab cc CodeCompanion]])
      vim.schedule(function()
        require("custom.codecompanion.codecompanion-spinner").spinner:init()
      end)
    end,
  },
}
