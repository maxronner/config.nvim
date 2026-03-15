local function scratch()
  vim.cmd.enew()
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
  vim.bo.buflisted = false
end

vim.api.nvim_create_user_command("Scratch", scratch, {})

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.g.startup_mode ~= "scratch" then
      return
    end

    vim.opt.shortmess:append("I")
    vim.g.ministarter_disable = true
    scratch()
  end,
})

vim.keymap.set("n", "<leader>bs", scratch, { desc = "Open scratch buffer" })
