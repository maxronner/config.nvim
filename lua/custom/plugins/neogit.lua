return {
  "NeogitOrg/neogit",
  cmd = "Neogit",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "sindrets/diffview.nvim", -- optional
    "ibhagwan/fzf-lua",
  },
  keys = {
    {
      "<leader>gg",
      function()
        require("neogit").open()
      end,
      desc = "Neogit: Open status",
    },
    {
      "<leader>qg",
      function()
        require("neogit").action("log", "log_current", { "--graph", "--decorate" })()
      end,
      desc = "Neogit: Log current branch",
    },
  },
  config = function()
    local neogit = require("neogit")

    local function warn_unsaved_buffers()
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_get_option_value("modified", { buf = buf }) then
          vim.notify("Warning: You have unsaved buffers!", vim.log.levels.WARN)
          break
        end
      end
    end

    local function update_submodules()
      vim.system({ "git", "submodule", "update", "--remote", "--recursive" }, { text = true }, function(result)
        vim.schedule(function()
          if result.code == 0 then
            vim.notify("Updated git submodules.", vim.log.levels.INFO)
            neogit.refresh()
            return
          end

          local message = result.stderr ~= "" and result.stderr or result.stdout
          vim.notify("Failed to update git submodules:\n" .. vim.trim(message), vim.log.levels.ERROR)
        end)
      end)
    end

    neogit.setup({
      integrations = {
        fzf_lua = true,
      },
      mappings = {
        status = {
          ["<leader>s"] = update_submodules,
        },
      },
    })

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("NeogitConfig", { clear = true }),
      pattern = "NeogitStatus",
      callback = warn_unsaved_buffers,
    })
  end,
}
