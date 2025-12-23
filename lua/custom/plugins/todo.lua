return {
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      -- your configuration comes here
      -- or leave it empty to use the default settings
      -- refer to the configuration section below
      keys = {
        {},
        { "n", "[#", function() require("todo-comments").jump_prev() end, { desc = "Previous todo comment" } },
      },
    },
    config = function()
      local todo_comments = require("todo-comments")
      todo_comments.setup()

      vim.keymap.set("n", "]#", function()
        require("todo-comments").jump_next()
      end, { desc = "Next todo comment" })

      vim.keymap.set("n", "[#", function()
        require("todo-comments").jump_prev()
      end, { desc = "Previous todo comment" })

      vim.keymap.set("n", "<leader>ft", ":TodoFzfLua<CR>", { desc = "Fzf: TODOs" })
    end,
  }
}
