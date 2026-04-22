local M = {}

local DEFAULT_HOST = '127.0.0.1'
local DEFAULT_BASE_PORT = 40000
local DEFAULT_PORT_SPAN = 20000
local DEFAULT_WAIT_MS = 5000
local DEFAULT_WAIT_INTERVAL_MS = 100

local function command_output(args, deps)
  local system = (deps and deps.system) or vim.fn.system
  local shell_error = (deps and deps.shell_error) or function()
    return vim.v.shell_error
  end

  local output = system(args)
  if shell_error() ~= 0 then
    return nil, vim.trim(output or '')
  end

  return vim.trim(output or '')
end

function M.current_tmux_session(deps)
  local tmux = deps and deps.tmux
  if tmux then
    local session = tmux()
    if session == nil or session == '' then
      return nil
    end

    return session
  end

  local output = vim.fn.system({ 'tmux', 'display-message', '-p', '#S' })
  if vim.v.shell_error ~= 0 then
    return nil
  end

  local session = vim.trim(output)
  if session == '' then
    return nil
  end

  return session
end

function M.deterministic_port(session_name, deps)
  if type(session_name) ~= 'string' or session_name == '' then
    error('invalid tmux session name: ' .. vim.inspect(session_name))
  end

  local base_port = (deps and deps.base_port) or DEFAULT_BASE_PORT
  local port_span = (deps and deps.port_span) or DEFAULT_PORT_SPAN

  local command = string.format(
    "printf '%%s' %s | cksum | awk '{ print %d + ($1 %% %d) }'",
    vim.fn.shellescape(session_name),
    base_port,
    port_span
  )

  local output, err = command_output({ 'sh', '-c', command }, deps)
  if not output then
    error(err ~= '' and err or 'failed to derive opencode port')
  end

  local port = tonumber(output)
  if not port then
    error('failed to derive opencode port')
  end

  return port
end

function M.session_port(session_name, deps)
  local output, err = command_output({ 'tmux', 'show-environment', '-t', session_name, 'OPENCODE_PORT' }, deps)
  if output then
    local port = vim.trim(output):match('^OPENCODE_PORT=(%d+)$')
    if port then
      return tonumber(port)
    end
  end

  local port = M.deterministic_port(session_name, deps)
  local _, err = command_output({ 'tmux', 'set-environment', '-t', session_name, 'OPENCODE_PORT', tostring(port) }, deps)
  if err then
    error(err ~= '' and err or 'failed to set OPENCODE_PORT')
  end

  return port
end

function M.endpoint_healthy(endpoint, deps)
  local host = endpoint.host or DEFAULT_HOST
  local output, err = command_output({ 'curl', '-fsS', string.format('http://%s:%d/global/health', host, endpoint.port) }, deps)
  if not output then
    return false, err
  end

  return true, nil
end

function M.start_server(session_name, port, deps)
  local host = (deps and deps.host) or DEFAULT_HOST
  local launcher = (deps and deps.launcher) or vim.env.OPENCODE_TMUX_LAUNCHER or 'opencode-serve'
  local wait = (deps and deps.wait) or vim.wait
  local wait_ms = (deps and deps.wait_ms) or DEFAULT_WAIT_MS
  local interval_ms = (deps and deps.interval_ms) or DEFAULT_WAIT_INTERVAL_MS
  local endpoint = { host = host, port = port, session_name = session_name }

  local healthy = M.endpoint_healthy(endpoint, deps)
  if healthy then
    return endpoint
  end

  local _, err = command_output({
    'tmux',
    'new-window',
    '-d',
    '-t',
    session_name .. ':',
    '-n',
    'opencode',
    launcher,
  }, deps)
  if err then
    error(err ~= '' and err or ('failed to start opencode tmux window for session ' .. session_name))
  end

  local became_healthy = wait(wait_ms, function()
    return M.endpoint_healthy(endpoint, deps)
  end, interval_ms)

  if not became_healthy then
    error(string.format('opencode server did not become healthy for tmux session %s on %s:%d', session_name, host, port))
  end

  return endpoint
end

function M.ensure_endpoint(deps)
  local session_name = M.current_tmux_session(deps)
  if not session_name then
    error('unable to resolve opencode endpoint: not running inside tmux')
  end

  local host = (deps and deps.host) or DEFAULT_HOST
  local port = M.session_port(session_name, deps)
  local endpoint = { host = host, port = port, session_name = session_name }

  if M.endpoint_healthy(endpoint, deps) then
    return endpoint
  end

  return M.start_server(session_name, port, deps)
end

function M.server_options(deps)
  local session_name = M.current_tmux_session(deps)
  if not session_name then
    return {
      start = false,
      stop = false,
      toggle = false,
    }
  end

  local host = (deps and deps.host) or DEFAULT_HOST
  local port = M.session_port(session_name, deps)

  return {
    host = host,
    port = port,
    start = function()
      M.start_server(session_name, port, deps)
    end,
    stop = false,
    toggle = false,
  }
end

function M.apply_endpoint(endpoint)
  vim.g.opencode_opts = vim.tbl_deep_extend('force', vim.g.opencode_opts or {}, {
    server = {
      host = endpoint.host or DEFAULT_HOST,
      port = endpoint.port,
      start = false,
      stop = false,
      toggle = false,
    },
  })
end

return M
