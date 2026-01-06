require("luasnip.loaders.from_vscode").lazy_load()
local ls = require("luasnip")

ls.config.set_config({
  history = true,
  updateevents = "TextChanged,TextChangedI",
  override_builtin = true,
})

for _, ft_path in ipairs(vim.api.nvim_get_runtime_file("lua/custom/snippets/*.lua", true)) do
  loadfile(ft_path)()
end

vim.keymap.set({ "i", "s" }, "<C-j>", function()
  if ls.jumpable(1) then
    ls.jump(1)
  end
end, { silent = true, desc = "Next snippet" })

vim.keymap.set({ "i", "s" }, "<C-k>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end, { silent = true, desc = "Previous snippet" })
