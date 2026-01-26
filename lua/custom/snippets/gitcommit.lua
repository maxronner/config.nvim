local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node

ls.add_snippets("gitcommit", {
  s("choredeps", t("chore(deps): Update Neovim configuration submodule")),
  s("lazylock", t("chore(deps): Update lazy-lock.json")),
})
