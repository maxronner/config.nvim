return {
  "tpope/vim-fugitive",
  config = function()
    vim.keymap.set("n", "<leader>gg", function()
      local success = pcall(vim.cmd.Git)
      if not success then
        vim.cmd.Git({ "init" })
        vim.cmd.Git()
      end
    end, { desc = "Fugitive: Open window" })
    vim.keymap.set("n", "<leader>gl", ":Gclog<CR>", { desc = "Fugitive: Log to quickfix" })

    local FugitiveConfig = vim.api.nvim_create_augroup("FugitiveConfig", {})
    local autocmd = vim.api.nvim_create_autocmd
    autocmd("FileType", {
      group = FugitiveConfig,
      pattern = "fugitive",
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        local opts = { buffer = bufnr, remap = false }

        local function nmap(lhs, rhs, desc)
          vim.keymap.set("n", lhs, rhs, vim.tbl_extend("force", opts, { desc = "Fugitive: " .. desc }))
        end

        nmap("<leader>p", function()
          vim.cmd.Git("push")
        end, "Push")

        nmap("<leader>P", function()
          vim.cmd.Git({ "push", "-u", "origin" })
        end, "Push with upstream")

        nmap("<leader>u", function()
          vim.cmd.Git({ "pull" })
        end, "Pull")

        nmap("<leader>U", function()
          vim.cmd.Git({ "pull", "--rebase" })
        end, "Pull with rebase")

        nmap(
          "<leader>s",
          ":Git submodule update --remote --recursive<CR>",
          "Initialize and update all git submodules recursively"
        )

        nmap("<leader>cc", function()
          vim.cmd.Git({ "commit", "--amend" })
        end, "Amend commit")

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_get_option_value("modified", { buf = buf }) then
            vim.notify("Warning: You have unsaved buffers!", vim.log.levels.WARN)
            break
          end
        end
      end,
    })
  end,
}
