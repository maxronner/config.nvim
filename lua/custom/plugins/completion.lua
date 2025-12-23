return {
  {
    "hrsh7th/nvim-cmp",
    lazy = false,
    priority = 100,
    dependencies = {
      "onsails/lspkind.nvim",
      "hrsh7th/cmp-nvim-lsp",
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
        config = function()
          require("supermaven-nvim").setup {
            keymaps = {
              accept_suggestion = "<C-a>",
              clear_suggestion = "<C-]>",
              accept_word = "<C-f>",
            },
            disable_inline_completion = false,
          }
          vim.keymap.set("n", "<leader>iq", "<cmd>SupermavenToggle<CR>",
            { noremap = true, silent = true, desc = "Supermaven: Toggle" })
        end,
      },
    },
    config = function()
      require "custom.completion"
    end,
  },
}
