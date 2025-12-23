return {
  "nvim-telescope/telescope.nvim",
  enabled = false,
  dependencies = {
    "nvim-lua/plenary.nvim",

    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },

    -- Lists files based on 'frecency' algorithm.
    "nvim-telescope/telescope-frecency.nvim",

    -- Sets prompt history to be project specific.
    "nvim-telescope/telescope-smart-history.nvim",
    "kkharji/sqlite.lua",

    -- Sets vim.ui.select to telescope.
    "nvim-telescope/telescope-ui-select.nvim",

    -- Icons for telescope.
    "nvim-tree/nvim-web-devicons",
  },

  config = function()
    require "custom.telescope"
  end
}
