return {
  "nvim-treesitter/nvim-treesitter",
  event = "VimEnter",
  branch = "main",
  dependencies = {
    {
      "nvim-treesitter/nvim-treesitter-textobjects",
      branch = "main",
    },
  },
  config = function()
    require("custom.treesitter").setup()
  end,
}
