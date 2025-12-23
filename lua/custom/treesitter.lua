local M = {}

M.setup = function()
  local group = vim.api.nvim_create_augroup("custom-treesitter", { clear = true })
  local ts = require("nvim-treesitter")
  ts.setup {
    install_dir = vim.fn.stdpath('data') .. '/site'
  }

  ts.install {
    "core",
    "stable",
    "gitcommit",
    "diff",
  }

  local syntax_on = {
    markdown = true,
  }

  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    callback = function(args)
      local bufnr = args.buf
      local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
      if not ok or not parser then
        return
      end
      pcall(vim.treesitter.start)

      local ft = vim.bo[bufnr].filetype
      if syntax_on[ft] then
        vim.bo[bufnr].syntax = "on"
      end
    end,
  })

  require 'nvim-treesitter-textobjects'.setup {
    lsp_interop = {
      enable = true,
      border = 'rounded',
      floating_preview_opts = {},
      peek_definition_code = {
        ["<leader>gf"] = "@function.outer",
        ["<leader>gF"] = "@class.outer",
      },
    },
    select = {
      enable = true,
      keymaps = {
        ["af"] = "@function.outer",
        ["if"] = "@function.inner",
        ["ac"] = "@class.outer",
      },
    },
    move = {
      enable              = true,
      set_to_root         = true,
      set_jumps           = true, -- whether to set jumps in the jumplist
      goto_next_start     = {
        ["]m"] = "@function.outer",
        ["]]"] = { query = "@class.outer", desc = "Next class start" },
        --
        -- You can use regex matching (i.e. lua pattern) and/or pass a list in a "query" key to group multiple queries.
        ["]o"] = "@loop.*",
        -- ["]o"] = { query = { "@loop.inner", "@loop.outer" } }
        --
        -- You can pass a query group to use query from `queries/<lang>/<query_group>.scm file in your runtime path.
        -- Below example nvim-treesitter's `locals.scm` and `folds.scm`. They also provide highlights.scm and indent.scm.
        ["]s"] = { query = "@local.scope", query_group = "locals", desc = "Next scope" },
        ["]z"] = { query = "@fold", query_group = "folds", desc = "Next fold" },
      },
      goto_next_end       = {
        ["]M"] = "@function.outer",
        ["]["] = "@class.outer",
      },
      goto_previous_start = {
        ["[m"] = "@function.outer",
        ["[["] = "@class.outer",
      },
      goto_previous_end   = {
        ["[M"] = "@function.outer",
        ["[]"] = "@class.outer",
      },
      -- Below will go to either the start or the end, whichever is closer.
      -- Use if you want more granular movements
      -- Make it even more gradual by adding multiple queries and regex.
      goto_next           = {
        ["]d"] = "@conditional.outer",
      },
      goto_previous       = {
        ["[d"] = "@conditional.outer",
      }
    },
    swap = {
      enable = true,
      swap_next = {
        ["<leader>ww"] = "@parameter.inner",
      },
      swap_previous = {
        ["<leader>ws"] = "@parameter.inner",
      },
    }
  }
end

return M
