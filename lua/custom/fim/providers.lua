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

local function parse_completion(decoded)
  if type(decoded) ~= "table" or type(decoded.choices) ~= "table" then
    return nil
  end

  local texts = {}
  for _, choice in ipairs(decoded.choices) do
    if type(choice) == "table" and type(choice.text) == "string" and choice.text ~= "" then
      table.insert(texts, choice.text)
    end
  end

  if #texts == 0 then
    return nil
  end

  return table.concat(texts, "\n")
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

local function sse_payloads(data)
  local payloads = {}

  for line in (data or ""):gmatch("[^\r\n]+") do
    line = vim.trim(line)
    if line:sub(1, 5) == "data:" then
      local payload = vim.trim(line:sub(6))
      if payload ~= "" and payload ~= "[DONE]" then
        table.insert(payloads, payload)
      end
    elseif line ~= "" and line:sub(1, 1) ~= ":" then
      table.insert(payloads, line)
    end
  end

  return payloads
end

local function response_error_message(stdout, stderr, result_code, timeout)
  local message = vim.trim(table.concat(stderr))
  local payloads = sse_payloads(table.concat(stdout))

  for _, payload in ipairs(payloads) do
    local decoded = decode_json(payload)
    if decoded and decoded.error then
      return decoded.error.message or decoded.error.type or payload
    end
  end

  if message ~= "" then
    return message
  end

  if result_code == 28 then
    return ("request timed out after %ds waiting for DeepSeek FIM response"):format(timeout)
  end

  if #payloads > 0 then
    return table.concat(payloads, "\n")
  end

  return "curl exited " .. result_code
end

function M.deepseek(ctx, provider_opts, callbacks)
  local api_key = vim.env[provider_opts.api_key_env or "DEEPSEEK_API_KEY"]
  if not api_key or api_key == "" then
    callbacks.on_error(("Missing %s"):format(provider_opts.api_key_env or "DEEPSEEK_API_KEY"))
    return function() end
  end

  local stream = provider_opts.stream == true
  local body = vim.json.encode({
    model = provider_opts.model or "deepseek-v4-pro",
    prompt = ctx.prefix,
    suffix = ctx.suffix ~= "" and ctx.suffix or nil,
    max_tokens = provider_opts.max_tokens or 96,
    temperature = provider_opts.temperature or 0,
    stream = stream,
  })

  local carry = ""
  local closed = false
  local timeout = provider_opts.timeout or 20
  local cmd = {
    "curl",
    "-sS",
    "-N",
    "--fail-with-body",
    "--max-time",
    tostring(timeout),
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
      if not stream then
        return
      end

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
    end,
  }, function(result)
    vim.schedule(function()
      if closed then
        return
      end

      if result.code == 0 then
        if not stream then
          local decoded = decode_json(table.concat(stdout))
          local text = parse_completion(decoded)
          if text and text ~= "" then
            callbacks.on_text(text)
          end
        end
        callbacks.on_done()
      else
        callbacks.on_error(("DeepSeek FIM failed: %s"):format(response_error_message(stdout, stderr, result.code, timeout)))
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

M._response_error_message = response_error_message
M._parse_completion = parse_completion

return M
