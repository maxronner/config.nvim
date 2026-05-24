local config = require("custom.fim.config")
local context = require("custom.fim.context")
local providers = require("custom.fim.providers")
local renderer = require("custom.fim.renderer")

local M = {}

local state = {
  timer = nil,
  request_id = 0,
  cancel = nil,
  completion = "",
  last_status = "idle",
  last_error = nil,
  pending_rest = nil,
}

local function in_insert_mode()
  return vim.api.nvim_get_mode().mode:sub(1, 1) == "i"
end

local function forward_segment(text)
  if text == "" then
    return ""
  end

  local newline = text:find("\n", 1, true)
  if newline == 1 then
    local next_newline = text:find("\n", 2, true)
    if next_newline then
      return text:sub(1, next_newline - 1)
    end
    return text
  end

  if newline then
    text = text:sub(1, newline - 1)
  end

  return text:match("^%s*[%w_]+") or text:match("^%s*%p") or text:match("^%s+") or text
end

local function cancel_request()
  if state.cancel then
    state.cancel()
    state.cancel = nil
  end
end

local function stale(request_id, ctx)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local cursor_row = math.max(cursor[1], 1) - 1
  return request_id ~= state.request_id
    or not vim.api.nvim_buf_is_valid(ctx.bufnr)
    or vim.api.nvim_buf_get_changedtick(ctx.bufnr) ~= ctx.changedtick
    or ctx.bufnr ~= vim.api.nvim_get_current_buf()
    or ctx.row ~= cursor_row
    or ctx.col ~= cursor[2]
end

function M.dismiss()
  state.request_id = state.request_id + 1
  state.completion = ""
  state.pending_rest = nil
  state.last_status = "idle"
  cancel_request()
  renderer.clear()
end

function M.accept_all()
  local current = renderer.current()
  if not current or not current.text or current.text == "" then
    return nil
  end

  local ctx = current.ctx
  if stale(state.request_id, ctx) then
    M.dismiss()
    return nil
  end

  M.dismiss()
  return current.text
end

function M.accept_forward()
  local current = renderer.current()
  if not current or not current.text or current.text == "" then
    return nil
  end

  local ctx = current.ctx
  if stale(state.request_id, ctx) then
    M.dismiss()
    return nil
  end

  local accepted = forward_segment(current.text)
  local rest = current.text:sub(#accepted + 1)
  M.dismiss()
  state.pending_rest = rest ~= "" and rest or nil

  return accepted
end

function M.show_pending_rest()
  local rest = state.pending_rest
  if not rest or rest == "" or not in_insert_mode() then
    state.pending_rest = nil
    return
  end

  state.pending_rest = nil
  local opts = config.options
  local next_ctx = context.collect(0, opts)
  state.request_id = state.request_id + 1
  state.completion = rest
  state.last_status = "partial accept"
  state.last_error = nil
  renderer.show(next_ctx, rest, opts)
end

function M.toggle()
  local opts = config.options
  opts.enabled = not opts.enabled

  if not opts.enabled then
    M.dismiss()
  end

  vim.notify("FIM " .. (opts.enabled and "enabled" or "disabled"), vim.log.levels.INFO, { title = "FIM" })
end

function M.status()
  local opts = config.options
  local provider_opts = opts.provider or {}
  local api_key_env = provider_opts.api_key_env or "DEEPSEEK_API_KEY"
  local api_key_state = vim.env[api_key_env] and vim.env[api_key_env] ~= "" and "set" or "missing"
  local current = renderer.current()

  local lines = {
    "enabled: " .. tostring(opts.enabled),
    "auto: " .. tostring(opts.auto),
    "api key: " .. api_key_env .. " " .. api_key_state,
    "status: " .. state.last_status,
    "ghost text: " .. (current and "visible" or "none"),
  }

  if state.last_error then
    table.insert(lines, "last error: " .. state.last_error)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "FIM status" })
end

function M.trigger(source)
  local opts = config.options
  if not opts.enabled then
    state.last_status = "disabled"
    if source == "manual" then
      vim.notify("FIM disabled", vim.log.levels.INFO, { title = "FIM" })
    end
    return
  end

  local ctx = context.collect(0, opts)
  if #ctx.prefix < opts.min_prefix_chars then
    state.last_status = "waiting for more prefix"
    if source == "manual" then
      vim.notify(
        ("Need at least %d prefix chars"):format(opts.min_prefix_chars),
        vim.log.levels.INFO,
        { title = "FIM" }
      )
    end
    return
  end
  local provider_opts = opts.provider or {}
  local api_key_env = provider_opts.api_key_env or "DEEPSEEK_API_KEY"
  if (provider_opts.name or "deepseek") == "deepseek" and (not vim.env[api_key_env] or vim.env[api_key_env] == "") then
    state.last_status = "missing api key"
    if source == "manual" then
      vim.notify(("Missing %s"):format(api_key_env), vim.log.levels.WARN, { title = "FIM" })
    end
    return
  end

  M.dismiss()

  state.request_id = state.request_id + 1
  local request_id = state.request_id
  state.completion = ""
  state.last_status = "requesting"
  state.last_error = nil

  state.cancel = providers.complete(ctx, opts, {
    on_text = function(text)
      if stale(request_id, ctx) then
        M.dismiss()
        return
      end

      state.completion = (state.completion .. text):sub(1, opts.max_completion_chars)
      state.last_status = "streaming"
      renderer.show(ctx, state.completion, opts)
    end,
    on_done = function()
      if stale(request_id, ctx) then
        M.dismiss()
      end
      if state.completion == "" then
        state.last_status = "empty response"
      else
        state.last_status = "done"
      end
      state.cancel = nil
    end,
    on_error = function(message)
      if stale(request_id, ctx) then
        return
      end

      state.cancel = nil
      state.last_status = "error"
      state.last_error = message
      renderer.clear(ctx.bufnr)
      vim.notify(message, vim.log.levels.WARN, { title = "FIM" })
    end,
  })
end

function M.schedule()
  local opts = config.options
  if not opts.enabled or not opts.auto then
    return
  end

  if state.pending_rest or renderer.current() then
    return
  end

  if state.timer then
    state.timer:stop()
    state.timer:close()
  end

  state.timer = vim.defer_fn(function()
    state.timer = nil
    if in_insert_mode() then
      M.trigger("auto")
    end
  end, opts.debounce_ms)
end

function M.setup(opts)
  opts = config.setup(opts)

  local group = vim.api.nvim_create_augroup("custom-fim", { clear = true })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = group,
    desc = "Refresh FIM completion after insert changes",
    callback = function()
      if state.pending_rest then
        vim.schedule(M.show_pending_rest)
      else
        M.schedule()
      end
    end,
  })
  vim.api.nvim_create_autocmd("CursorMovedI", {
    group = group,
    desc = "Schedule FIM completion",
    callback = M.schedule,
  })
  vim.api.nvim_create_autocmd({ "InsertLeave", "BufLeave" }, {
    group = group,
    desc = "Dismiss FIM completion",
    callback = M.dismiss,
  })

  vim.keymap.set("i", opts.manual_key, function()
    M.trigger("manual")
  end, { desc = "FIM: Trigger completion" })

  vim.keymap.set("n", opts.manual_normal_key, function()
    M.trigger("manual")
  end, { desc = "FIM: Trigger completion" })

  vim.keymap.set("n", opts.toggle_key, function()
    M.toggle()
  end, { desc = "FIM: Toggle completion" })

  vim.api.nvim_create_user_command("FimStatus", function()
    M.status()
  end, { desc = "Show FIM status" })

  vim.keymap.set("i", opts.dismiss_key, function()
    M.dismiss()
    return ""
  end, { expr = true, desc = "FIM: Dismiss completion" })

  vim.keymap.set("i", opts.accept_all_key, function()
    return M.accept_all() or ""
  end, { expr = true, replace_keycodes = false, desc = "FIM: Accept completion" })

  vim.keymap.set("i", opts.accept_forward_key, function()
    local accepted = M.accept_forward()
    if not accepted then
      return ""
    end

    return accepted
  end, { expr = true, replace_keycodes = false, desc = "FIM: Accept forward" })
end

return M
