return {
  {
    "folke/zen-mode.nvim",
    dependencies = {
      {
        "folke/twilight.nvim",
        opts = {
          exclude = {
            "markdown",
            "help",
          }
        }
      }
    },
    opts = {
      window = {
        backdrop = 1,
        width = 80,
        options = {
          number = false,
          relativenumber = false,
          signcolumn = "no",
          colorcolumn = ""
        },
      },
      plugins = {
        options = {
          enabled = true,
          ruler = false,
          showcmd = false,
          laststatus = 0,
        },
        twilight = { enabled = true },
        gitsigns = { enabled = false },
        tmux = { enabled = true },
      },
    },
    keys = {
      { "<leader>zm", "<cmd>ZenMode<CR>", desc = "Toggle Zen Mode" },
    }
  }
}
