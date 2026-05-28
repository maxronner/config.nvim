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

function M.state()
  return state
end

function M.cancel()
  if state.cancel then
    state.cancel()
    state.cancel = nil
  end
end

function M.clear_completion()
  state.completion = ""
  state.last_status = "idle"
  M.cancel()
end

function M.next_request()
  state.request_id = state.request_id + 1
  return state.request_id
end

function M.set_status(status, last_error)
  state.last_status = status
  if last_error ~= nil then
    state.last_error = last_error
  end
end

function M.set_completion(text, status)
  state.completion = text
  state.last_error = nil
  if status then
    state.last_status = status
  end
  return state.completion
end

function M.append_completion(text, max_chars)
  state.completion = (state.completion .. text):sub(1, max_chars)
  state.last_status = "streaming"
  return state.completion
end

function M.set_cancel(cancel)
  state.cancel = cancel
end

function M.finish_request()
  state.last_status = state.completion == "" and "empty response" or "done"
  state.cancel = nil
end

function M.fail_request(message)
  state.cancel = nil
  state.last_status = "error"
  state.last_error = message
end

return M
