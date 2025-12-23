local function is_gpg_locked(err_msg)
  return err_msg:match("decryption failed")
      or err_msg:match("no secret key")
      or err_msg:match("No secret key")
      or err_msg:match("No agent running")
      or err_msg:match("can't open")
      or err_msg:match("Permission denied")
      or err_msg:match("Inappropriate ioctl")
end

local function get_pass_entry(entry)
  local res = vim.system({ "pass", entry }, { text = true }):wait()
  if res.code == 0 then
    return vim.trim(res.stdout), nil
  end

  local err_msg = vim.trim(res.stderr or "")
  if is_gpg_locked(err_msg) then
    local fallback = vim.fn.system({ "pass", entry })
    if vim.v.shell_error == 0 then
      return vim.trim(fallback), nil
    else
      return nil, vim.trim(fallback)
    end
  end

  return nil, err_msg ~= "" and err_msg or "Unknown error"
end

local function get_pass_entry_async(entry, callback)
  vim.system({ "pass", entry }, { text = true }, function(res)
    if res.code == 0 then
      callback(vim.trim(res.stdout), nil)
    else
      local err_msg = vim.trim(res.stderr or "")
      if is_gpg_locked(err_msg) then
        local result = vim.fn.system({ "pass", entry })
        if vim.v.shell_error == 0 then
          callback(vim.trim(result), nil)
        else
          callback(nil, vim.trim(result))
        end
      else
        callback(nil, err_msg ~= "" and err_msg or "Unknown error")
      end
    end
  end)
end

local M = {}
M.keys = {}              -- var -> value
M.lazy_entries = {}      -- var -> pass path
M.pending_callbacks = {} -- var -> list of callbacks
M.loading = {}           -- var -> true if loading

--- Register once for both sync and async
local function register_lazy_key(pass_entry, var)
  M.lazy_entries[var] = pass_entry
end

--- Internal async fetcher, deduplicated
local function fetch_key_async(var, cb)
  if M.keys[var] ~= nil then
    cb(M.keys[var], nil)
    return
  end

  if M.loading[var] then
    table.insert(M.pending_callbacks[var], cb)
    return
  end

  M.loading[var] = true
  M.pending_callbacks[var] = { cb }

  local entry = M.lazy_entries[var]
  get_pass_entry_async(entry, function(val, err)
    if val then
      M.keys[var] = val
    end

    for _, callback in ipairs(M.pending_callbacks[var] or {}) do
      callback(val, err)
    end

    M.loading[var] = nil
    M.pending_callbacks[var] = nil
  end)
end

--- Public sync fetcher (blocking)
function M.get_var(var)
  if M.keys[var] then
    return M.keys[var]
  end

  local entry = M.lazy_entries[var]
  if not entry then
    vim.notify("No lazy key registered for " .. var, vim.log.levels.DEBUG)
    return nil
  end

  local val, err = get_pass_entry(entry)
  if val then
    M.keys[var] = val
    return val
  else
    vim.notify("Failed to load " .. var .. ": " .. err, vim.log.levels.ERROR)
    return nil
  end
end

--- Public async fetcher (non-blocking)
function M.get_var_async(var, cb)
  if M.keys[var] then
    cb(M.keys[var], nil)
    return
  end

  if not M.lazy_entries[var] then
    cb(nil, "No lazy key registered for " .. var)
    return
  end

  fetch_key_async(var, cb)
end

function M.export_var(var)
  local val = M.get_var(var)
  if val then
    vim.env[var] = val
    return true
  end
  return false
end

function M.export_var_async(var, cb)
  M.get_var_async(var, function(val, err)
    if val then
      vim.schedule(function()
        vim.env[var] = val
        cb(true, nil)
      end)
    else
      cb(false, err)
    end
  end)
end

-- Register all keys once
register_lazy_key("Credentials/keys/openai", "OPENAI_API_KEY")
register_lazy_key("Credentials/keys/gemini", "GEMINI_API_KEY")
register_lazy_key("Credentials/keys/tavily", "TAVILY_API_KEY")

return M
