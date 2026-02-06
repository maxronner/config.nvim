local function is_gpg_locked(err_msg)
  local msg = (err_msg or ""):lower()
  return msg:match("decryption failed")
    or msg:match("no secret key")
    or msg:match("no agent running")
    or msg:match("can't open")
    or msg:match("permission denied")
    or msg:match("inappropriate ioctl")
    or msg:match("gpg%-agent")
end

local function trim_or_empty(val)
  return vim.trim(val or "")
end

local function normalize_err(err_msg)
  local err = trim_or_empty(err_msg)
  return err ~= "" and err or "Unknown error"
end

local function pass_result(res)
  if res.code == 0 then
    return { ok = true, val = trim_or_empty(res.stdout) }
  end

  local err_raw = trim_or_empty(res.stderr)
  if is_gpg_locked(err_raw) then
    return { ok = false, locked = true, err = err_raw }
  end

  return { ok = false, locked = false, err = normalize_err(err_raw) }
end

local function pass_fallback_sync(entry)
  local fallback = vim.fn.system({ "pass", entry }) or ""
  if vim.v.shell_error == 0 then
    return trim_or_empty(fallback), nil
  end
  return nil, normalize_err(fallback)
end

local function get_pass_entry(entry)
  local res = vim.system({ "pass", entry }, { text = true }):wait()
  local result = pass_result(res)
  if result.ok then
    return result.val, nil
  end

  if result.locked then
    return pass_fallback_sync(entry)
  end

  return nil, result.err
end

local function get_pass_entry_async(entry, callback)
  local function on_first(res)
    local result = pass_result(res)
    if result.ok then
      callback(result.val, nil)
    else
      if result.locked then
        local val, err = pass_fallback_sync(entry)
        callback(val, err)
        return
      end
      callback(nil, result.err)
    end
  end

  vim.system({ "pass", entry }, { text = true }, on_first)
end

local M = {}
M.state = {} -- var -> { value, entry, pending, loading }

local function get_state(var)
  local st = M.state[var]
  if not st then
    st = { pending = {}, loading = false }
    M.state[var] = st
  end
  return st
end

--- Register once for both sync and async
local function register_lazy_key(pass_entry, var)
  local st = get_state(var)
  st.entry = pass_entry
end

local function finish_callbacks(st, val, err)
  local pending = st.pending or {}
  st.pending = {}
  st.loading = false
  for _, cb in ipairs(pending) do
    cb(val, err)
  end
end

--- Internal async fetcher, deduplicated
local function fetch_key_async(var, cb)
  local st = M.state[var]
  if not st or not st.entry then
    cb(nil, "No lazy key registered for " .. var)
    return
  end

  if st.value ~= nil then
    cb(st.value, nil)
    return
  end

  if st.loading then
    st.pending = st.pending or {}
    table.insert(st.pending, cb)
    return
  end

  st.loading = true
  st.pending = { cb }

  get_pass_entry_async(st.entry, function(val, err)
    if val then
      st.value = val
    end

    finish_callbacks(st, val, err)
  end)
end

--- Public async fetcher (non-blocking)
function M.get_var_async(var, cb)
  local st = M.state[var]
  if st and st.value ~= nil then
    cb(st.value, nil)
    return
  end

  if not st or not st.entry then
    cb(nil, "No lazy key registered for " .. var)
    return
  end

  fetch_key_async(var, cb)
end

--- Public sync fetcher (blocking)
function M.get_var(var)
  local st = M.state[var]
  if st and st.value ~= nil then
    return st.value
  end

  if not st or not st.entry then
    vim.notify("No lazy key registered for " .. var, vim.log.levels.DEBUG)
    return nil
  end

  local val, err = get_pass_entry(st.entry)
  if val then
    st.value = val
    return val
  else
    vim.notify("Failed to load " .. var .. ": " .. err, vim.log.levels.ERROR)
    return nil
  end
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
    vim.schedule(function()
      if val then
        vim.env[var] = val
        cb(true, nil)
      else
        cb(false, err)
      end
    end)
  end)
end

-- Register all keys once
register_lazy_key("api/llm/openai", "OPENAI_API_KEY")
register_lazy_key("api/llm/gemini", "GEMINI_API_KEY")
register_lazy_key("api/llm/anthropic", "ANTHROPIC_API_KEY")
register_lazy_key("api/llm/tavily", "TAVILY_API_KEY")

return M
