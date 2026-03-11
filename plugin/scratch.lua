function OpenScratch()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end

vim.keymap.set("n", "<leader>bs", OpenScratch, { desc = "Open scratch buffer" })
