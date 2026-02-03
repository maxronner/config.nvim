return {
  interaction = "chat",
  description = "Generate conventional commit message",
  opts = {
    alias = "gitcommit",
    adapter = {
      name = "gemini",
      model = "gemini-2.5-flash",
    },
  },
  prompts = {
    {
      role = "system",
      content = [[
Wrap gitcommit with:
```gitcommit
```
]],
    },
    {
      role = "user",
      content = function()
        local diff = vim.fn.system("git diff --staged")
        if diff == "" then
          return "There are no staged changes."
        end

        return [[
You are an expert at following the Conventional Commit specification. Given the git diff listed below, please generate a commit message for me:

```diff
]] .. diff .. [[
```
]]
      end,
    },
  },
}
