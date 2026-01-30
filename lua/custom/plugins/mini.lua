return {
  {
    "nvim-mini/mini.indentscope",
    event = "BufReadPre",
    config = function()
      require("mini.indentscope").setup({
        draw = {
          delay = 0,
          animation = require("mini.indentscope").gen_animation.none(),
        },
      })
      vim.api.nvim_create_autocmd("Filetype", {
        callback = function(args)
          local buftype = vim.bo[args.buf].buftype
          if buftype == "nofile" or buftype == "prompt" or buftype == "help" or buftype == "qf" then
            vim.b.miniindentscope_disable = true
          else
            vim.b.miniindentscope_disable = false
          end
        end,
      })
    end,
  },
  {
    "nvim-mini/mini.surround",
    keys = {
      { "sa", mode = { "n", "x" } },
      { "sd", mode = { "n", "x" } },
      { "sr", mode = { "n", "x" } },
    },
    config = function()
      require("mini.surround").setup()
    end,
  },
  {
    "nvim-mini/mini.clue",
    event = "VeryLazy",
    config = function()
      local miniclue = require("mini.clue")
      miniclue.setup({
        triggers = {
          -- Leader triggers
          { mode = "n", keys = "<Leader>" },
          { mode = "x", keys = "<Leader>" },

          -- Built-in completion
          { mode = "i", keys = "<C-x>" },

          -- `g` key
          { mode = "n", keys = "g" },
          { mode = "x", keys = "g" },

          -- Marks
          { mode = "n", keys = "'" },
          { mode = "n", keys = "`" },
          { mode = "x", keys = "'" },
          { mode = "x", keys = "`" },

          -- Registers
          { mode = "n", keys = '"' },
          { mode = "x", keys = '"' },
          { mode = "i", keys = "<C-r>" },
          { mode = "c", keys = "<C-r>" },

          -- Window commands
          { mode = "n", keys = "<C-w>" },

          -- `z` key
          { mode = "n", keys = "z" },
          { mode = "x", keys = "z" },
        },

        clues = {
          -- Enhance this by adding descriptions for <Leader> mapping groups
          miniclue.gen_clues.builtin_completion(),
          miniclue.gen_clues.g(),
          miniclue.gen_clues.marks(),
          miniclue.gen_clues.registers(),
          miniclue.gen_clues.windows(),
          miniclue.gen_clues.z(),
        },
        window = {
          delay = 300,
          config = {
            width = "auto",
            border = "double",
          },
        },
      })
    end,
  },
  {
    "nvim-mini/mini.comment",
    keys = { "gc" },
    config = function()
      require("mini.comment").setup()
    end,
  },
  {
    "nvim-mini/mini.ai",
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup()
    end,
  },
  {
    "nvim-mini/mini.align",
    keys = { "ga", "gA" },
    config = function()
      require("mini.align").setup()
    end,
  },
  {
    "nvim-mini/mini.bracketed",
    keys = { "[", "]" },
    config = function()
      require("mini.bracketed").setup()
    end,
  },
  {
    "nvim-mini/mini.move",
    keys = {
      { "<M-j>", mode = { "n", "v" } },
      { "<M-k>", mode = { "n", "v" } },
      { "<M-h>", mode = { "n", "v" } },
      { "<M-l>", mode = { "n", "v" } },
    },
    config = function()
      require("mini.move").setup()
    end,
  },
  {
    "nvim-mini/mini.jump",
    event = "VeryLazy",
    config = function()
      require("mini.jump").setup()
    end,
  },
  {
    "nvim-mini/mini.operators",
    keys = { "gr", "gm", "gs", "gx", "g==" },
    config = function()
      require("mini.operators").setup()
    end,
  },
  {
    "nvim-mini/mini.trailspace",
    event = "BufReadPre",
    config = function()
      require("mini.trailspace").setup()
      vim.api.nvim_create_autocmd("BufWritePre", {
        callback = function()
          MiniTrailspace.trim()
          MiniTrailspace.trim_last_lines()
        end,
      })
    end,
  },
  {
    "nvim-mini/mini.splitjoin",
    keys = { "gS" },
    config = function()
      require("mini.splitjoin").setup()
    end,
  },
  {
    "nvim-mini/mini.cursorword",
    event = "VeryLazy",
    config = function()
      require("mini.cursorword").setup()
      local function disable_current_word_highlight()
        vim.api.nvim_set_hl(0, "MiniCursorwordCurrent", {})
      end
      disable_current_word_highlight()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = disable_current_word_highlight,
      })
    end,
  },
  {
    "nvim-mini/mini.cmdline",
    event = "CmdlineEnter",
    config = function()
      require("mini.cmdline").setup()
    end,
  },
  {
    "nvim-mini/mini.starter",
    lazy = false,
    config = function()
      require("mini.starter").setup(require("custom.starter"))
    end,
  },
  {
    "nvim-mini/mini.statusline",
    lazy = false,
    config = function()
      require("mini.statusline").setup()
    end,
  },
  {
    "nvim-mini/mini.icons",
    lazy = false,
    config = function()
      require("mini.icons").setup()
    end,
  },
}
