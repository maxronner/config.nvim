vim.api.nvim_create_user_command("Scratch", function()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end, {})

vim.keymap.set("n", "<leader>bs", "<cmd>Scratch<CR>", { desc = "Open scratch buffer" })
