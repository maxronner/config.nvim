return {
  {
    "nickjvandyke/opencode.nvim",
    dependencies = {
      "ibhagwan/fzf-lua",
    },
    config = function()
      local router = require("custom.opencode_tmux")

      vim.o.autoread = true

      vim.g.opencode_opts = {
        server = router.server_options(),
        select = {
          sections = {
            server = false,
          },
        },
        lsp = {
          enabled = false,
        },
      }
    end,
    keys = {
      {
        "<leader>ia",
        function()
          require("opencode").ask("@this: ", { submit = true })
        end,
        mode = { "n", "x" },
        desc = "Opencode: Ask",
      },
      {
        "<leader>is",
        function()
          require("opencode").select()
        end,
        mode = { "n", "x" },
        desc = "Opencode: Select",
      },
      {
        "<leader>ii",
        function()
          require("opencode").prompt("@this ")
        end,
        mode = "x",
        desc = "Opencode: Add selection",
      },
      {
        "<leader>ii",
        function()
          return require("opencode").operator("@this ")
        end,
        expr = true,
        desc = "Opencode: Add motion",
      },
      {
        "<leader>il",
        function()
          require("opencode").command("session.select")
        end,
        desc = "Opencode: Select session",
      },
      {
        "<leader>in",
        function()
          require("opencode").command("session.new")
        end,
        desc = "Opencode: New session",
      },
    },
  },
}
