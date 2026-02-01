return {
  {
    "ibhagwan/fzf-lua",
    enabled = true,
    cmd = "FzfLua",
    keys = {
      {
        "<leader>/",
        function()
          require("fzf-lua").lines()
        end,
        desc = "Fzf: Fuzzy find in current buffer",
      },
      {
        "<leader>fb",
        function()
          require("fzf-lua").buffers()
        end,
        desc = "Fzf: Buffers",
      },
      {
        "<leader>fP",
        function()
          require("fzf-lua").files({ no_ignore = true })
        end,
        desc = "Fzf: Find files (all)",
      },
      {
        "<leader>fp",
        function()
          require("fzf-lua").files({ hidden = false })
        end,
        desc = "Fzf: Find files (no hidden, no ignored)",
      },
      {
        "<leader>fo",
        function()
          require("fzf-lua").oldfiles()
        end,
        desc = "Fzf: Find old files",
      },
      {
        "<leader>fi",
        function()
          require("fzf-lua").git_files()
        end,
        desc = "Fzf: Git files",
      },
      {
        "<leader>fl",
        function()
          require("fzf-lua").live_grep()
        end,
        desc = "Fzf: Live grep",
      },
      {
        "<leader>fg",
        function()
          require("fzf-lua").grep()
        end,
        desc = "Fzf: Grep",
      },
      {
        "<leader>fw",
        function()
          require("fzf-lua").grep_visual()
        end,
        mode = "x",
        desc = "Fzf: Grep selection",
      },
      {
        "<leader>fw",
        function()
          require("fzf-lua").grep_cword()
        end,
        desc = "Fzf: Grep word under cursor",
      },
      {
        "<leader>fc",
        function()
          require("fzf-lua").git_branches()
        end,
        desc = "Fzf: Git branch checkout",
      },
      {
        "<leader>fm",
        function()
          require("fzf-lua").git_status()
        end,
        desc = "Fzf: Git status",
      },
      {
        "<leader>:",
        function()
          require("fzf-lua").command_history()
        end,
        desc = "Fzf: Command history",
      },
      {
        "<leader>fH",
        function()
          require("fzf-lua").search_history()
        end,
        desc = "Fzf: Search history",
      },
      {
        "<leader>fh",
        function()
          require("fzf-lua").helptags()
        end,
        desc = "Fzf: Help tags",
      },
      {
        "<leader>fk",
        function()
          require("fzf-lua").keymaps()
        end,
        desc = "Fzf: Keymaps",
      },
      {
        "<leader>fO",
        function()
          require("fzf-lua").nvim_options()
        end,
        desc = "Fzf: Nvim options",
      },
      {
        "<leader>vv",
        function()
          require("fzf-lua").files({ cwd = vim.fn.stdpath("config") })
        end,
        desc = "Fzf: Find files in Neovim config",
      },
      {
        "<leader>vl",
        function()
          require("fzf-lua").files({ cwd = vim.fn.stdpath("data") .. "/lazy" })
        end,
        desc = "Fzf: Find files in plugins",
      },
      {
        "<leader>fd",
        function()
          require("fzf-lua").lsp_definitions()
        end,
        desc = "Fzf: LSP Definitions",
      },
      {
        "<leader>fr",
        function()
          require("fzf-lua").lsp_references()
        end,
        desc = "Fzf: LSP References",
      },
      {
        "<leader>ls",
        function()
          require("fzf-lua").lsp_document_symbols()
        end,
        desc = "Fzf: LSP Document Symbols",
      },
    },
    dependencies = { "nvim-mini/mini.icons" },
    opts = {},
    config = function()
      require("custom.fzf")
    end,
  },
}
