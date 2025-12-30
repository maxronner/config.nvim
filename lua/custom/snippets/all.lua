local ls = require("luasnip")
local s = ls.snippet
local f = ls.function_node
local t = ls.text_node
local i = ls.insert_node
local fmt = require("luasnip.extras.fmt").fmt
local rep = require("luasnip.extras").rep

ls.add_snippets("all", {
  s("hello", t("Hello World!")),
  s(
    "curtime",
    f(function()
      return os.date("%Y-%m-%d %H:%M:%S")
    end)
  ),
  s(
    "date",
    f(function()
      return os.date("%Y-%m-%d")
    end)
  ),
  s(
    "time",
    f(function()
      return os.date("%H:%M:%S")
    end)
  ),
  s(
    "mr",
    f(function()
      return "Max Ronner"
    end)
  ),
  s(
    "es",
    f(function()
      return "Best regards, Max Ronnner"
    end)
  ),
})
