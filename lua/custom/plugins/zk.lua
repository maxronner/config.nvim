return {
  "zk-org/zk-nvim",
  cmd = {
    "ZkCd",
    "ZkNew",
    "ZkSync",
    "ZkTags",
    "ZkDaily",
    "ZkIndex",
    "ZkLinks",
    "ZkMatch",
    "ZkNotes",
    "ZkWeekly",
    "ZkBuffers",
    "ZkBacklinks",
    "ZkYesterday",
    "ZkInsertLink",
    "ZkInsertLinkAtSelection",
    "ZkNewFromTitleSelection",
    "ZkNewFromContentSelection",
  },
  keys = {
    { "<leader>zd", "<Cmd>ZkDaily<CR>", desc = "Zettelkasten: Daily Note" },
    { "<leader>zD", "<Cmd>ZkYesterday<CR>", desc = "Zettelkasten: Yesterday" },
    { "<leader>zn", "<Cmd>ZkNew<CR>", desc = "Zettelkasten: New Note" },
    { "<leader>zo", "<Cmd>ZkNotes { sort = { 'modified' } }<CR>", desc = "Zettelkasten: Open Note" },
    { "<leader>zt", "<Cmd>ZkTags<CR>", desc = "Zettelkasten: Show Tags" },
    {
      "<leader>zf",
      "<Cmd>ZkNotes { sort = { 'modified' }, match = { vim.fn.input('Search: ') } }<CR>",
      desc = "Zettelkasten: Search Notes",
    },
    { "<leader>zs", "<Cmd>ZkSync<CR>", desc = "Zettelkasten: Git Sync" },
    { "<leader>zi", "<Cmd>ZkInsertLink<CR>", desc = "Zettelkasten: Insert Link" },
    {
      "<leader>zf",
      ":'<,'>ZkMatch<CR>",
      desc = "Zettelkasten: Search for Selection",
      mode = "v",
    },
  },
  config = function()
    require("zk").setup({
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

    local new = require("zk.commands").get("ZkNew")
    vim.api.nvim_create_user_command("ZkNew", function()
      local title = vim.fn.input("Title: ")
      if title == "" then
        return
      end
      new({
        dir = "notes",
        title = title,
      })
    end, {})

    vim.api.nvim_create_user_command("ZkDaily", function()
      new({ dir = "journal/daily", no_input = true })
    end, {})

    vim.api.nvim_create_user_command("ZkWeekly", function()
      new({ dir = "journal/weekly", no_input = true })
    end, {})

    vim.api.nvim_create_user_command("ZkYesterday", function()
      local date = os.date("%Y-%m-%d", os.time() - 86400)
      new({
        date = date,
        dir = "journal/daily",
        no_input = true,
      })
    end, {})

    vim.api.nvim_create_user_command("ZkSync", function()
      local notebook_dir = os.getenv("ZK_NOTEBOOK_DIR") or "~/notebook"
      local sync_script = vim.fn.expand("~/.local/bin/zk-sync")

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
