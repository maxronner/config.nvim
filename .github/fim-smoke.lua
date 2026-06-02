local session = require("custom.fim.session")
local config = require("custom.fim.config")
local providers = require("custom.fim.providers")
local renderer = require("custom.fim.renderer")
local fim = require("custom.fim")

local function assert_snapshot_is_copy()
  session.set_completion("abc", "done")

  local snapshot = session.snapshot()
  snapshot.completion = "changed"

  assert(session.snapshot().completion == "abc", "session.snapshot should not expose mutable state")
  assert(snapshot.last_status == "done", "session.snapshot should include status")
end

local function assert_request_lifecycle()
  local first = session.next_request()
  local second = session.next_request()

  assert(second == first + 1, "session.next_request should increment request id")
  assert(session.request_id() == second, "session.request_id should return current request id")
end

local function assert_completion_lifecycle()
  session.set_completion("abc", "requesting")
  assert(session.snapshot().completion == "abc", "session.set_completion should set completion")
  assert(session.last_status() == "requesting", "session.set_completion should set status")
  assert(session.last_non_idle_status() == "requesting", "session should remember the last non-idle status")

  local completion = session.append_completion("def", 5)
  assert(completion == "abcde", "session.append_completion should cap completion")
  assert(session.last_status() == "streaming", "session.append_completion should mark streaming")

  session.finish_request()
  assert(session.last_status() == "done", "session.finish_request should mark non-empty completion done")

  session.set_completion("", "requesting")
  session.finish_request()
  assert(session.last_status() == "empty response", "session.finish_request should mark empty completion")

  session.fail_request("failed")
  assert(session.last_status() == "error", "session.fail_request should mark error")
  assert(session.last_error() == "failed", "session.fail_request should store error")

  session.clear_completion()
  assert(session.last_status() == "idle", "session.clear_completion should mark idle")
  assert(session.last_non_idle_status() == "error", "session should retain last non-idle status after clearing")
end

local function assert_pending_rest_lifecycle()
  session.clear_pending_rest()
  assert(not session.has_pending_rest(), "session.clear_pending_rest should clear pending rest")

  assert(session.set_pending_rest("") == nil, "session.set_pending_rest should ignore empty text")
  assert(not session.has_pending_rest(), "empty pending rest should not count as pending")

  assert(session.set_pending_rest("tail") == "tail", "session.set_pending_rest should store text")
  assert(session.has_pending_rest(), "session.has_pending_rest should report stored text")
  assert(session.take_pending_rest() == "tail", "session.take_pending_rest should return stored text")
  assert(not session.has_pending_rest(), "session.take_pending_rest should clear stored text")
end

local function assert_timer_lifecycle()
  local stopped = false
  local closed = false
  local timer = {
    stop = function()
      stopped = true
    end,
    close = function()
      closed = true
    end,
  }

  session.set_timer(timer)
  session.stop_timer()

  assert(stopped, "session.stop_timer should stop existing timer")
  assert(closed, "session.stop_timer should close existing timer")
  assert(session.snapshot().timer == nil, "session.stop_timer should clear timer")
end

local function assert_provider_error_message_ignores_sse_comments()
  local message = providers._response_error_message({ ": keep-alive\n" }, {}, 28, 20)
  assert(
    message == "request timed out after 20s waiting for DeepSeek FIM response",
    "provider timeout errors should not report SSE keep-alive comments as the failure"
  )
end

local function assert_provider_parses_non_stream_completion()
  local text = providers._parse_completion({
    choices = {
      {
        text = "d",
      },
    },
  })

  assert(text == "d", "provider should parse non-stream completion text")
  assert(config.defaults.provider.stream == false, "FIM provider should default to non-streaming completions")
end

local function assert_renderer_uses_cursor_window_column_virtual_text()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "Hello worl" })
  vim.api.nvim_win_set_cursor(0, { 1, 10 })

  renderer.show({
    bufnr = bufnr,
    row = 0,
    col = 10,
  }, "d", {
    highlight = "Comment",
  })

  local marks = vim.api.nvim_buf_get_extmarks(bufnr, renderer.namespace(), 0, -1, { details = true })
  assert(#marks == 1, "renderer.show should create a ghost text extmark")
  assert(marks[1][4].virt_text_win_col == 9, "renderer ghost text should pin to cursor window column")

  renderer.clear(bufnr)
  vim.api.nvim_buf_delete(bufnr, { force = true })
end

local function assert_accept_uses_eol_renderer_state()
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_set_current_buf(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, { "This is our phil" })
  vim.api.nvim_win_set_cursor(0, { 1, 16 })

  local ctx = {
    bufnr = bufnr,
    row = 0,
    col = 16,
    changedtick = vim.api.nvim_buf_get_changedtick(bufnr),
  }
  session.next_request()
  session.set_completion("osophy", "done")
  renderer.show(ctx, "osophy", {
    highlight = "Comment",
  })

  assert(fim.accept_all() == "osophy", "accept_all should return stored EOL completion")
  assert(renderer.current() == nil, "accept_all should clear rendered ghost text")

  vim.api.nvim_buf_delete(bufnr, { force = true })
end

assert_snapshot_is_copy()
assert_request_lifecycle()
assert_completion_lifecycle()
assert_pending_rest_lifecycle()
assert_timer_lifecycle()
assert_provider_error_message_ignores_sse_comments()
assert_provider_parses_non_stream_completion()
assert_renderer_uses_cursor_window_column_virtual_text()
assert_accept_uses_eol_renderer_state()
