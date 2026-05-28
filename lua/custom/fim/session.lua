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

return M
