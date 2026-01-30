return {
  "nvim-treesitter/nvim-treesitter",
  event = "VeryLazy",
  branch = "main",
  build = ":TSUpdate",
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
