local session = require("custom.fim.session")

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

assert_snapshot_is_copy()
assert_request_lifecycle()
assert_completion_lifecycle()
assert_pending_rest_lifecycle()
assert_timer_lifecycle()
