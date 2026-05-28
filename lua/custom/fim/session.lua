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

return M
