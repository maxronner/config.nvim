return {
  "tpope/vim-fugitive",
  config = function()
    vim.keymap.set("n", "<leader>gg", vim.cmd.Git, { desc = "Fugitive: Open window" })
    vim.keymap.set("n", "<leader>gb", ":Git blame<CR>", { desc = "Fugitive: Blame" })
    vim.keymap.set("n", "<leader>qg", ":Gclog<CR>", { desc = "Fugitive: Log to quickfix" })

    local maxronner_Fugitive = vim.api.nvim_create_augroup("maxronner_Fugitive", {})
    local autocmd = vim.api.nvim_create_autocmd
    autocmd("BufWinEnter", {
      group = maxronner_Fugitive,
      pattern = "*",
      callback = function()
        if vim.bo.ft ~= "fugitive" then
          return
        end

        local bufnr = vim.api.nvim_get_current_buf()
        local opts = { buffer = bufnr, remap = false }

        vim.keymap.set("n", "<leader>p", function()
          vim.cmd.Git("push")
        end, vim.tbl_extend("force", opts, { desc = "Fugitive: Push" }))

        vim.keymap.set("n", "<leader>u", function()
          vim.cmd.Git({ "pull" })
        end, vim.tbl_extend("force", opts, { desc = "Fugitive: Pull" }))

        vim.keymap.set(
          "n",
          "<leader>U",
          ":Git submodule update --remote --recursive",
          vim.tbl_extend("force", opts, { desc = "Fugitive: Initialize and update all git submodules recursively" })
        )

        vim.keymap.set("n", "<leader>P", function()
          vim.cmd.Git({ "pull", "--rebase" })
        end, vim.tbl_extend("force", opts, { desc = "Fugitive: Pull --rebase" }))

        vim.keymap.set(
          "n",
          "<leader>t",
          ":Git push -u origin ",
          vim.tbl_extend("force", opts, { desc = "Fugitive: Push with upstream" })
        )

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
