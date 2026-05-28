local config = require("custom.fim.config")
local context = require("custom.fim.context")
local providers = require("custom.fim.providers")
local renderer = require("custom.fim.renderer")
local safety = require("custom.fim.safety")
local session = require("custom.fim.session")

local M = {}
local state = session.state()

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

local function clear_completion()
  session.clear_completion()
  renderer.clear()
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
  session.next_request()
  session.clear_pending_rest()
  clear_completion()
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
  session.next_request()
  clear_completion()
  if session.set_pending_rest(rest) then
    vim.defer_fn(function()
      M.show_pending_rest()
    end, 20)
    vim.defer_fn(function()
      M.show_pending_rest()
    end, 80)
  end

  return accepted
end

function M.show_pending_rest()
  if not session.has_pending_rest() then
    session.clear_pending_rest()
    return
  end
  if not in_insert_mode() then
    return
  end

  local rest = session.take_pending_rest()
  local opts = config.options
  local next_ctx = context.collect(0, opts)
  session.next_request()
  session.set_completion(rest, "partial accept")
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
  local blocked = safety.reason(0, nil, opts)

  local lines = {
    "enabled: " .. tostring(opts.enabled),
    "auto: " .. tostring(opts.auto),
    "api key: " .. api_key_env .. " " .. api_key_state,
    "blocked: " .. (blocked or "no"),
    "status: " .. state.last_status,
    "ghost text: " .. (current and "visible" or "none"),
    "pending rest: " .. (session.has_pending_rest() and "yes" or "no"),
  }

  if state.last_error then
    table.insert(lines, "last error: " .. state.last_error)
  end

  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO, { title = "FIM status" })
end

function M.trigger(source)
  local opts = config.options
  if not opts.enabled then
    session.set_status("disabled")
    if source == "manual" then
      vim.notify("FIM disabled", vim.log.levels.INFO, { title = "FIM" })
    end
    return
  end

  local blocked = safety.reason(0, nil, opts)
  if blocked then
    M.dismiss()
    session.set_status("blocked", blocked)
    if source == "manual" then
      vim.notify("FIM blocked: " .. blocked, vim.log.levels.WARN, { title = "FIM" })
    end
    return
  end

  local ctx = context.collect(0, opts)
  if #ctx.prefix < opts.min_prefix_chars then
    session.set_status("waiting for more prefix")
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
    session.set_status("missing api key")
    if source == "manual" then
      vim.notify(("Missing %s"):format(api_key_env), vim.log.levels.WARN, { title = "FIM" })
    end
    return
  end

  M.dismiss()

  local request_id = session.next_request()
  session.set_completion("", "requesting")

  session.set_cancel(providers.complete(ctx, opts, {
    on_text = function(text)
      if stale(request_id, ctx) then
        M.dismiss()
        return
      end

      renderer.show(ctx, session.append_completion(text, opts.max_completion_chars), opts)
    end,
    on_done = function()
      if stale(request_id, ctx) then
        M.dismiss()
      end
      session.finish_request()
    end,
    on_error = function(message)
      if stale(request_id, ctx) then
        return
      end

      session.fail_request(message)
      renderer.clear(ctx.bufnr)
      vim.notify(message, vim.log.levels.WARN, { title = "FIM" })
    end,
  }))
end

function M.schedule()
  local opts = config.options
  if not opts.enabled or not opts.auto then
    return
  end

  if safety.reason(0, nil, opts) then
    M.dismiss()
    session.set_status("blocked")
    return
  end

  if session.has_pending_rest() or renderer.current() then
    return
  end

  session.stop_timer()

  local timer
  timer = vim.defer_fn(function()
    session.clear_timer(timer)
    if in_insert_mode() then
      M.trigger("auto")
    end
  end, opts.debounce_ms)
  session.set_timer(timer)
end

function M.setup(opts)
  opts = config.setup(opts)

  local group = vim.api.nvim_create_augroup("custom-fim", { clear = true })
  vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "BufFilePost" }, {
    group = group,
    desc = "Block FIM for sensitive buffers before reading text",
    callback = function(args)
      safety.mark(args.buf, args.file, opts)
    end,
  })
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    desc = "Block FIM for sensitive filetypes",
    callback = function(args)
      safety.mark(args.buf, vim.api.nvim_buf_get_name(args.buf), opts)
    end,
  })
  vim.api.nvim_create_autocmd("TextChangedI", {
    group = group,
    desc = "Refresh FIM completion after insert changes",
    callback = function()
      if session.has_pending_rest() then
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
