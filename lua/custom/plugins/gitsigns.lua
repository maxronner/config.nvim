return {
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require("gitsigns").setup({
        on_attach = function(bufnr)
          local gitsigns = require("gitsigns")

          gitsigns.setup({
            signs = {
              add = { text = "▎" },
              change = { text = "▎" },
              delete = { text = "▎" },
              topdelete = { text = "▎" },
              changedelete = { text = "▎" },
              untracked = { text = "▎" },
            },
            signs_staged = {
              add = { text = "▏" },
              change = { text = "▏" },
            },
          })

          local function map(mode, l, r, opts)
            opts = opts or {}
            opts.buffer = bufnr
            vim.keymap.set(mode, l, r, opts)
          end

          -- Navigation
          map("n", "]c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              gitsigns.nav_hunk("next")
            end
          end, { desc = "Next hunk" })

          map("n", "[c", function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              gitsigns.nav_hunk("prev")
            end
          end, { desc = "Previous hunk" })

          -- Actions
          map("n", "<leader>gs", gitsigns.stage_hunk, { desc = "Gitsigns: Stage hunk" })
          map("n", "<leader>gr", gitsigns.reset_hunk, { desc = "Gitsigns: Reset hunk" })

          map("v", "<leader>gs", function()
            gitsigns.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Gitsigns: Stage hunk" })

          map("v", "<leader>gr", function()
            gitsigns.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end, { desc = "Gitsigns: Reset hunk" })

          map("n", "<leader>gS", gitsigns.stage_buffer, { desc = "Gitsigns: Stage buffer" })
          map("n", "<leader>gR", gitsigns.reset_buffer, { desc = "Gitsigns: Reset buffer" })

          map("n", "<leader>gp", gitsigns.preview_hunk, { desc = "Gitsigns: Preview hunk" })
          map("n", "<leader>gi", gitsigns.preview_hunk_inline, { desc = "Gitsigns: Preview hunk inline" })

          map("n", "<leader>gB", gitsigns.blame_line, { desc = "Gitsigns: Blame line" })
          map("n", "<leader>gb", gitsigns.blame, { desc = "Gitsigns: Blame" })

          map("n", "<leader>gd", gitsigns.diffthis, { desc = "Gitsigns: Diff this" })
          map("n", "<leader>gq", gitsigns.setqflist, { desc = "Gitsigns: All changes to quickfix list" })

          -- Toggles
          map("n", "<leader>gtl", gitsigns.toggle_current_line_blame, { desc = "Toggle current line blame" })
          map("n", "<leader>gtw", gitsigns.toggle_word_diff, { desc = "Toggle word diff" })

          -- Text object
          map({ "o", "x" }, "ih", gitsigns.select_hunk, { desc = "Select hunk" })
        end,
      })
    end,
  },
}
