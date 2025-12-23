local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

ls.add_snippets("lua", {
  s("lf", fmt("local {} = function({})\n\t{}\nend", { i(1, "name"), i(2, "args"), i(0) })),
  s("req", fmt([[local {} = require "{}"]], {
    f(function(import_name)
      local parts = vim.split(import_name[1][1], ".", { plain = true })
      return parts[#parts] or ""
    end, { 1 }),
    i(1),
  }))
})
