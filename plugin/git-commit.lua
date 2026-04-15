---@alias CommitBackend "gemini"|"openai"|"ollama"

---@type CommitBackend
local backend = "gemini"

---@type table<CommitBackend, fun(prompt: string, api_key: string?, cb: fun(out: string?, err: string?))>
local backends = {
  gemini = function(prompt, api_key, cb)
    if not api_key then
      cb(nil, "GEMINI_API_KEY not found")
      return
    end
    local body = vim.json.encode({
      contents = { { parts = { { text = prompt } } } },
    })
    vim.system({
      "curl",
      "-s",
      "-w",
      "\n%{http_code}",
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent?key=" .. api_key,
      "-H",
      "Content-Type: application/json",
      "-d",
      body,
    }, { text = true }, function(obj)
      if obj.code ~= 0 or not obj.stdout then
        cb(nil, "curl failed: exit " .. obj.code)
        return
      end
      local raw = obj.stdout
      local status = raw:match("\n(%d+)$")
      local resp_body = raw:gsub("\n%d+$", "")
      if status ~= "200" then
        cb(nil, "gemini HTTP " .. (status or "?"))
        return
      end
      local ok, data = pcall(vim.json.decode, resp_body)
      if ok and data.candidates and data.candidates[1] then
        cb(data.candidates[1].content.parts[1].text)
      else
        local api_err = ok and data.error and data.error.message
        cb(nil, api_err or "gemini: unexpected response")
      end
    end)
  end,

  openai = function(prompt, api_key, cb)
    if not api_key then
      cb(nil, "OPENAI_API_KEY not found")
      return
    end
    local body = vim.json.encode({
      model = "gpt-4.1-nano",
      messages = { { role = "user", content = prompt } },
    })
    vim.system({
      "curl",
      "-s",
      "-w",
      "\n%{http_code}",
      "https://api.openai.com/v1/chat/completions",
      "-H",
      "Content-Type: application/json",
      "-H",
      "Authorization: Bearer " .. api_key,
      "-d",
      body,
    }, { text = true }, function(obj)
      if obj.code ~= 0 or not obj.stdout then
        cb(nil, "curl failed: exit " .. obj.code)
        return
      end
      local raw = obj.stdout
      local status = raw:match("\n(%d+)$")
      local resp_body = raw:gsub("\n%d+$", "")
      if status ~= "200" then
        cb(nil, "openai HTTP " .. (status or "?"))
        return
      end
      local ok, data = pcall(vim.json.decode, resp_body)
      if ok and data.choices and data.choices[1] then
        cb(data.choices[1].message.content)
      else
        local api_err = ok and data.error and data.error.message
        cb(nil, api_err or "openai: unexpected response")
      end
    end)
  end,

  ollama = function(prompt, _, cb)
    local body = vim.json.encode({
      model = "qwen3",
      prompt = prompt,
      stream = false,
    })
    vim.system({
      "curl",
      "-s",
      "-w",
      "\n%{http_code}",
      "http://localhost:11434/api/generate",
      "-d",
      body,
    }, { text = true }, function(obj)
      if obj.code ~= 0 or not obj.stdout then
        cb(nil, "curl failed: exit " .. obj.code .. " (ollama running?)")
        return
      end
      local raw = obj.stdout
      local status = raw:match("\n(%d+)$")
      local resp_body = raw:gsub("\n%d+$", "")
      if status ~= "200" then
        cb(nil, "ollama HTTP " .. (status or "?"))
        return
      end
      local ok, data = pcall(vim.json.decode, resp_body)
      if ok and data.response then
        cb(data.response)
      else
        cb(nil, "ollama: unexpected response")
      end
    end)
  end,
}

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

  local run = backends[backend]
  if not run then
    vim.notify("Unknown backend: " .. backend, vim.log.levels.ERROR)
    return
  end

  local key_for_backend = {
    gemini = "GEMINI_API_KEY",
    openai = "OPENAI_API_KEY",
  }
  local api_key = key_for_backend[backend] and require("custom.passloader").get_var(key_for_backend[backend])

  run(prompt, api_key, function(out, err)
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
