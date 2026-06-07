local pack = require("custom.pack")

local M = {}

local imports = {
  {
    module = "custom.plugins.mini",
  },
  {
    module = "custom.plugins.oil",
    include = {
      "oil.nvim",
    },
  },
  {
    module = "custom.plugins.fzf",
    include = {
      "fzf-lua",
    },
  },
  {
    module = "custom.plugins.gitsigns",
    include = {
      "gitsigns.nvim",
    },
  },
  {
    module = "custom.plugins.trouble",
    include = {
      "trouble.nvim",
    },
  },
  {
    module = "custom.plugins.todo",
    include = {
      "todo-comments.nvim",
    },
  },
  {
    module = "custom.plugins.harpoon",
    include = {
      "harpoon",
    },
  },
  {
    module = "custom.plugins.dial",
    include = {
      "dial.nvim",
    },
  },
  {
    module = "custom.plugins.zk",
    include = {
      "zk-nvim",
    },
  },
  {
    module = "custom.plugins.zen",
    include = {
      "zen-mode.nvim",
    },
  },
  {
    module = "custom.plugins.neogit",
    include = {
      "neogit",
    },
  },
  {
    module = "custom.plugins.treesitter",
    include = {
      "nvim-treesitter",
      "nvim-treesitter-textobjects",
    },
  },
  {
    module = "custom.plugins.present",
    include = {
      "present.nvim",
    },
  },
  {
    module = "custom.plugins.dap",
    include = {
      "nvim-dap",
    },
  },
  {
    module = "custom.plugins.opencode",
    include = {
      "opencode.nvim",
    },
  },
  {
    module = "custom.plugins.minuet",
    include = {
      "minuet-ai.nvim",
    },
  },
  {
    module = "custom.plugins.lsp",
    include = {
      "conform.nvim",
      "SchemaStore.nvim",
    },
  },
  {
    module = "custom.plugins.markdown",
    include = {
      "render-markdown.nvim",
    },
  },
}

function M.get()
  local specs = {}

  for _, import in ipairs(imports) do
    vim.list_extend(
      specs,
      pack.import(import.module, {
        include = import.include,
      })
    )
  end

  return specs
end

return M
