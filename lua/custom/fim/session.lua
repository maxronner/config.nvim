local M = {}

local state = {
  timer = nil,
  request_id = 0,
  cancel = nil,
  completion = "",
  last_status = "idle",
  last_non_idle_status = nil,
  last_error = nil,
  pending_rest = nil,
}

local function set_status(status)
  state.last_status = status
  if status ~= "idle" then
    state.last_non_idle_status = status
  end
end

function M.state()
  return state
end

function M.snapshot()
  return {
    timer = state.timer,
    request_id = state.request_id,
    cancel = state.cancel,
    completion = state.completion,
    last_status = state.last_status,
    last_non_idle_status = state.last_non_idle_status,
    last_error = state.last_error,
    pending_rest = state.pending_rest,
  }
end

function M.cancel()
  if state.cancel then
    state.cancel()
    state.cancel = nil
  end
end

function M.clear_completion()
  state.completion = ""
  set_status("idle")
  M.cancel()
end

function M.next_request()
  state.request_id = state.request_id + 1
  return state.request_id
end

function M.request_id()
  return state.request_id
end

function M.last_status()
  return state.last_status
end

function M.last_non_idle_status()
  return state.last_non_idle_status
end

function M.last_error()
  return state.last_error
end

function M.set_status(status, last_error)
  set_status(status)
  if last_error ~= nil then
    state.last_error = last_error
  end
end

function M.set_completion(text, status)
  state.completion = text
  state.last_error = nil
  if status then
    set_status(status)
  end
  return state.completion
end

function M.append_completion(text, max_chars)
  state.completion = (state.completion .. text):sub(1, max_chars)
  set_status("streaming")
  return state.completion
end

function M.set_cancel(cancel)
  state.cancel = cancel
end

function M.finish_request()
  set_status(state.completion == "" and "empty response" or "done")
  state.cancel = nil
end

function M.fail_request(message)
  state.cancel = nil
  set_status("error")
  state.last_error = message
end

function M.clear_pending_rest()
  state.pending_rest = nil
end

function M.set_pending_rest(text)
  state.pending_rest = text ~= "" and text or nil
  return state.pending_rest
end

function M.take_pending_rest()
  local rest = state.pending_rest
  state.pending_rest = nil
  return rest
end

function M.has_pending_rest()
  return state.pending_rest ~= nil
end

function M.stop_timer()
  if state.timer then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end
end

function M.set_timer(timer)
  state.timer = timer
end

function M.clear_timer(timer)
  if not timer or state.timer == timer then
    state.timer = nil
  end
end

return M
