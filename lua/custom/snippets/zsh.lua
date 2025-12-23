local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

ls.add_snippets("zsh", {
  s("shebang", {
    t({ "#!/usr/bin/env zsh", "" }),
    i(1, "# description"),
    t({ "", "" }),
  }),
})
