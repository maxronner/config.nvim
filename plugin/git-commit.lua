---@alias CommitBackend "gemini"|"openai"|"anthropic"

---@type CommitBackend
local backend = "gemini"

local function run_llm_prompt(prompt, provider, cb)
  vim.system({ "llm-prompt", "--provider", provider }, {
    text = true,
    stdin = prompt,
  }, function(obj)
    if obj.code ~= 0 then
      local err = vim.trim(obj.stderr or "")
      cb(nil, err ~= "" and err or ("llm-prompt failed: exit " .. obj.code))
      return
    end

    cb(obj.stdout)
  end)
end

local function gen_commit_msg()
  local diff = vim.fn.system("git diff --staged --no-color")

  if diff == "" then
    vim.notify("No staged changes", vim.log.levels.WARN)
    return
  end

  -- Preserve comment lines (scissors, status, template) from the buffer
  local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local comment_lines = {}
  for _, line in ipairs(buf_lines) do
    if line:match("^#") then
      table.insert(comment_lines, line)
    end
  end

  local prompt = table.concat({
    "Generate a git commit message for the following staged diff.",
    "Follow Conventional Commits: <type>[(scope)]: <description>",
    "Types: feat fix docs style refactor perf test build ci chore revert",
    "Subject line: imperative mood, no period, <=50 chars.",
    "If a body is needed, add a blank line then wrap at 72 chars.",
    "Output ONLY the commit message, no explanation or markdown fences.",
    "",
    diff,
  }, "\n")

  vim.notify("Generating commit message…")

  run_llm_prompt(prompt, backend, function(out, err)
    if not out or out:match("^%s*$") then
      vim.schedule(function()
        vim.notify("Commit msg failed: " .. (err or "empty response"), vim.log.levels.ERROR)
      end)
      return
    end

    local msg_lines = vim.split(out, "\n", { trimempty = true })

    -- Re-append comment lines below the generated message
    if #comment_lines > 0 then
      table.insert(msg_lines, "")
      vim.list_extend(msg_lines, comment_lines)
    end

    vim.schedule(function()
      vim.api.nvim_buf_set_lines(0, 0, -1, false, msg_lines)
      vim.api.nvim_win_set_cursor(0, { 1, 0 })
    end)
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.keymap.set("n", "<leader>ig", gen_commit_msg, { buffer = true, desc = "Generate commit message" })
  end,
})
