return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "onsails/lspkind.nvim",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-cmdline",
      {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        dependencies = {
          "rafamadriz/friendly-snippets",
          "saadparwaiz1/cmp_luasnip",
        },
      },
      {
        "supermaven-inc/supermaven-nvim",
        event = { "BufReadPre", "BufNewFile" },
        cmd = {
          "SupermavenStart",
          "SupermavenStop",
          "SupermavenToggle",
          "SupermavenStatus",
          "SupermavenRestart",
          "SupermavenLogout",
          "SupermavenShowLog",
          "SupermavenClearLog",
          "SupermavenUsePro",
          "SupermavenUseFree",
        },
        keys = {
          {
            "<leader>iq",
            "<cmd>SupermavenToggle<CR>",
            desc = "Supermaven: Toggle",
          },
        },
        opts = {
          keymaps = {
            accept_suggestion = "<C-a>",
            clear_suggestion = "<C-]>",
            accept_word = "<C-f>",
          },
        },
      },
    },
    config = function()
      require("custom.completion")
    end,
  },
}
