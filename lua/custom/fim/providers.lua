local M = {}

local function decode_json(payload)
  local ok, decoded = pcall(vim.json.decode, payload)
  if ok then
    return decoded
  end
end

local function parse_chunk(decoded)
  if type(decoded) ~= "table" or type(decoded.choices) ~= "table" then
    return nil
  end

  local choice = decoded.choices[1]
  if type(choice) ~= "table" then
    return nil
  end

  return choice.text or (choice.delta and choice.delta.content)
end

local function stream_sse(data, carry, on_text)
  carry = carry .. (data or "")

  while true do
    local newline = carry:find("\n", 1, true)
    if not newline then
      break
    end

    local line = vim.trim(carry:sub(1, newline - 1))
    carry = carry:sub(newline + 1)

    if line:sub(1, 5) == "data:" then
      local payload = vim.trim(line:sub(6))
      if payload ~= "" and payload ~= "[DONE]" then
        local decoded = decode_json(payload)
        local text = parse_chunk(decoded)
        if text and text ~= "" then
          on_text(text)
        end
      end
    end
  end

  return carry
end

function M.deepseek(ctx, provider_opts, callbacks)
  local api_key = vim.env[provider_opts.api_key_env or "DEEPSEEK_API_KEY"]
  if not api_key or api_key == "" then
    callbacks.on_error(("Missing %s"):format(provider_opts.api_key_env or "DEEPSEEK_API_KEY"))
    return function() end
  end

  local body = vim.json.encode({
    model = provider_opts.model or "deepseek-v4-pro",
    prompt = ctx.prefix,
    suffix = ctx.suffix ~= "" and ctx.suffix or nil,
    max_tokens = provider_opts.max_tokens or 96,
    temperature = provider_opts.temperature or 0,
    stream = true,
  })

  local carry = ""
  local closed = false
  local cmd = {
    "curl",
    "-sS",
    "-N",
    "--fail-with-body",
    "--max-time",
    tostring(provider_opts.timeout or 20),
    "-H",
    "Content-Type: application/json",
    "-H",
    "Authorization: Bearer " .. api_key,
    "-d",
    body,
    (provider_opts.base_url or "https://api.deepseek.com/beta") .. "/completions",
  }

  local stderr = {}
  local stdout = {}
  local handle = vim.system(cmd, {
    text = true,
    stdout = function(_, data)
      if closed or not data then
        return
      end

      table.insert(stdout, data)

      vim.schedule(function()
        if closed then
          return
        end
        carry = stream_sse(data, carry, callbacks.on_text)
      end)
    end,
    stderr = function(_, data)
      if closed or not data or data == "" then
        return
      end

      table.insert(stderr, data)
      vim.schedule(function()
        if not closed then
          callbacks.on_error(vim.trim(data))
        end
      end)
    end,
  }, function(result)
    vim.schedule(function()
      if closed then
        return
      end

      if result.code == 0 then
        callbacks.on_done()
      else
        local body = vim.trim(table.concat(stdout))
        local message = vim.trim(table.concat(stderr))
        if body ~= "" then
          local decoded = decode_json(body)
          if decoded and decoded.error then
            message = decoded.error.message or decoded.error.type or body
          else
            message = body
          end
        end

        callbacks.on_error(
          ("DeepSeek FIM failed: %s"):format(message ~= "" and message or ("curl exited " .. result.code))
        )
      end
    end)
  end)

  return function()
    closed = true
    if handle then
      handle:kill(15)
    end
  end
end

function M.complete(ctx, opts, callbacks)
  local provider = (opts.provider or {}).name or "deepseek"
  if provider == "deepseek" then
    return M.deepseek(ctx, opts.provider or {}, callbacks)
  end

  callbacks.on_error("Unknown FIM provider: " .. provider)
  return function() end
end

return M
