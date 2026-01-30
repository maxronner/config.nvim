return {
  "zk-org/zk-nvim",
  event = "VeryLazy",
  config = function()
    require("zk").setup({
      picker = "telescope",
      lsp = {
        -- `config` is passed to `vim.lsp.start(config)`
        config = {
          name = "zk",
          cmd = { "zk", "lsp" },
          filetypes = { "markdown" },
          -- on_attach = ...
          -- etc, see `:h vim.lsp.start()`
        },
        -- automatically attach buffers in a zk notebook that match the given filetypes
        auto_attach = {
          enabled = true,
        },
      },
    })

    local opts = { noremap = true, silent = false }
    local global_leader_maps = {
      ["<leader>zd"] = { "<Cmd>ZkDaily<CR>", "Zettelkasten: Daily Note" },
      ["<leader>zD"] = { "<Cmd>ZkYesterday<CR>", "Zettelkasten: Yesterday" },
      ["<leader>zn"] = { "<Cmd>ZkNew<CR>", "Zettelkasten: New Note" },
      ["<leader>zo"] = { "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", "Zettelkasten: Open Note" },
      ["<leader>zt"] = { "<Cmd>ZkTags<CR>", "Zettelkasten: Show Tags" },
      ["<leader>zf"] = {
        "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
        "Zettelkasten: Search Notes",
      },
      ["<leader>zs"] = { "<Cmd>ZkSync<CR>", "Zettelkasten: Git Sync" },
      ["<leader>zi"] = { "<Cmd>ZkInsertLink<CR>", "Zettelkasten: Insert Link" },
      -- Visual mode search for selection
      ["<leader>zf_v"] = { ":'<,'>ZkMatch<CR>", "Zettelkasten: Search for Selection", mode = "v" },
    }

    for key, map in pairs(global_leader_maps) do
      local mode = map.mode or "n"
      -- Remove _v suffix from key when setting visual mode mapping
      local keymap = key:gsub("_v$", "")
      vim.keymap.set(mode, keymap, map[1], vim.tbl_extend("force", opts, { desc = map[2] }))
    end

    vim.api.nvim_create_user_command("ZkNew", function()
      require("zk.commands").get("ZkNew")({
        dir = "notes",
        no_input = true,
      })
    end, {})

    vim.api.nvim_create_user_command("ZkDaily", function()
      require("zk.commands").get("ZkNew")({
        dir = "journal/daily",
        no_input = true,
      })
    end, {})

    vim.api.nvim_create_user_command("ZkWeekly", function()
      require("zk.commands").get("ZkNew")({
        dir = "journal/weekly",
        no_input = true,
      })
    end, {})

    vim.api.nvim_create_user_command("ZkYesterday", function()
      local date = os.date("%Y-%m-%d", os.time() - 86400)
      require("zk.commands").get("ZkNew")({
        date = date,
        dir = "journal/daily",
        no_input = true,
      })
    end, {})

    vim.api.nvim_create_user_command("ZkSync", function()
      local notebook_dir = os.getenv("ZK_NOTEBOOK_DIR") or "~/notebook"
      local sync_script = vim.fn.expand("~/.local/bin/zk-sync.sh")

      if vim.fn.filereadable(sync_script) == 0 then
        vim.notify("[zk-sync] Sync script not found: " .. sync_script, vim.log.levels.ERROR)
        return
      end

      -- Run in background to avoid blocking UI
      vim.fn.jobstart({ sync_script }, {
        cwd = notebook_dir,
        stdout_buffered = true,
        stderr_buffered = true,

        on_stdout = function(_, data)
          if data then
            local output = table.concat(data, "\n")
            if output:gsub("%s+", "") ~= "" then
              vim.notify("[zk-sync] " .. output, vim.log.levels.INFO)
            end
          end
        end,

        on_stderr = function(_, data)
          if data then
            local output = table.concat(data, "\n")
            if output:gsub("%s+", "") ~= "" then
              vim.notify("[zk-sync] " .. output, vim.log.levels.ERROR)
            end
          end
        end,
      })
    end, {
      desc = "Pull, stage, commit, and push ZK notes using zk-sync.sh",
    })
  end,
}
