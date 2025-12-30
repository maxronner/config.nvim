return {
  {
    "echasnovski/mini.nvim",
    config = function()
      require("mini.ai").setup()
      require("mini.cmdline").setup({
        autocomplete = {
          delay = 200,
        },
      })
      require("mini.surround").setup()
      require("mini.pairs").setup()
      require("mini.comment").setup()
      require("mini.move").setup()
      require("mini.operators").setup()
      require("mini.bracketed").setup()
      require("mini.trailspace").setup()
      require("mini.splitjoin").setup()
      require("mini.statusline").setup()
      require("mini.align").setup()
      require("mini.icons").setup()
      require("mini.jump").setup()
      require("mini.cursorword").setup()
      require("mini.starter").setup(require("custom.starter"))
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

      local map = require("mini.map")
      map.setup({
        integrations = {
          map.gen_integration.builtin_search(),
          map.gen_integration.gitsigns(),
          map.gen_integration.diagnostic(),
        },
        symbols = {
          encode = nil,
          scroll_view = "┃",
          scroll_line = "▶",
        },
        window = {
          show_integration_count = false,
          width = 8,
        },
      })
      vim.keymap.set("n", "<leader>m", MiniMap.toggle, { desc = "Toggle MiniMap" })

      vim.keymap.set("n", "<leader>bd", function()
        require("mini.bufremove").delete(0, false)
      end, { desc = "Delete buffer without closing window" })
    end,
  },
}
