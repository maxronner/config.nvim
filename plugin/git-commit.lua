---@class CustomGitCommitConfig
---@field model? string

---@type CustomGitCommitConfig
local config = vim.g.custom_git_commit or {}

local function run_llm_prompt(prompt, model, cb)
  local args = { "llm", "prompt", "--no-stream", "--no-log" }
  if model and model ~= "" then
    vim.list_extend(args, { "--model", model })
  end

  vim.system(args, {
    text = true,
    stdin = prompt,
  }, function(obj)
    if obj.code ~= 0 then
      local err = vim.trim(obj.stderr or "")
      cb(nil, err ~= "" and err or ("llm prompt failed: exit " .. obj.code))
      return
    end

    cb(obj.stdout)
  end)
end

local function gen_commit_msg()
  local commit_buf = vim.api.nvim_get_current_buf()
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

  run_llm_prompt(prompt, config.model, function(out, err)
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
      if not vim.api.nvim_buf_is_valid(commit_buf) then
        vim.notify("Commit buffer closed before message could be inserted", vim.log.levels.WARN)
        return
      end

      vim.api.nvim_buf_set_lines(commit_buf, 0, -1, false, msg_lines)
      local win = vim.fn.bufwinid(commit_buf)
      if win ~= -1 then
        vim.api.nvim_win_set_cursor(win, { 1, 0 })
      end
    end)
  end)
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.keymap.set("n", "<leader>ig", gen_commit_msg, { buffer = true, desc = "Generate commit message" })
  end,
})
