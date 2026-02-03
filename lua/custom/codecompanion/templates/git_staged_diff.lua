return {
  interaction = "chat",
  description = "Analyze git diff --staged",
  opts = {
    alias = "staged_diff",
    adapter = {
      name = "gemini",
      model = "gemini-2.5-flash",
    },
  },
  prompts = {
    {
      role = "system",
      content = [[
You are reviewing a staged Git diff.

Focus on:
- Intent
- Correctness
- Edge cases
- Security or performance concerns

Assume an experienced author.

Wrap output commit with:
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
Analyze the following staged diff:

```diff
]] .. diff .. [[
```
]]
      end,
    },
  },
}
