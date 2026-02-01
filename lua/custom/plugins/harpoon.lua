return {
  {
    "ThePrimeagen/harpoon",
    branch = "harpoon2",
    keys = {
      {
        "<C-a>",
        function()
          require("harpoon"):list():add()
        end,
        desc = "Harpoon: Add file to list",
      },
      {
        "<C-e>",
        function()
          local harpoon = require("harpoon")
          harpoon.ui:toggle_quick_menu(harpoon:list())
        end,
        desc = "Harpoon: Toggle quick menu",
      },
      {
        "<leader>t",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Harpoon: Jump to mark 1",
      },
      {
        "<leader>s",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Harpoon: Jump to mark 2",
      },
      {
        "<leader>r",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Harpoon: Jump to mark 3",
      },
      {
        "<leader>a",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Harpoon: Jump to mark 4",
      },
      {
        "<leader>1",
        function()
          require("harpoon"):list():select(1)
        end,
        desc = "Harpoon: Jump to mark 1 (alternate)",
      },
      {
        "<leader>2",
        function()
          require("harpoon"):list():select(2)
        end,
        desc = "Harpoon: Jump to mark 2 (alternate)",
      },
      {
        "<leader>3",
        function()
          require("harpoon"):list():select(3)
        end,
        desc = "Harpoon: Jump to mark 3 (alternate)",
      },
      {
        "<leader>4",
        function()
          require("harpoon"):list():select(4)
        end,
        desc = "Harpoon: Jump to mark 4 (alternate)",
      },
      {
        "<leader>p",
        function()
          require("harpoon"):list():prev()
        end,
        desc = "Harpoon: Previous mark",
      },
      {
        "<leader>n",
        function()
          require("harpoon"):list():next()
        end,
        desc = "Harpoon: Next mark",
      },
    },
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("harpoon"):setup()
    end,
  },
}
