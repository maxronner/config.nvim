local progress = require("fidget.progress")

local M = {}
M.spinner = {}

function M.spinner:init()
  local group = vim.api.nvim_create_augroup("CodeCompanionFidgetHooks", {})

  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "CodeCompanionRequestStarted",
    group = group,
    callback = function(request)
      local handle = M.spinner:create_progress_handle(request)
      M.spinner:store_progress_handle(request.data.id, handle)
    end,
  })



  vim.api.nvim_create_autocmd({ "User" }, {
    pattern = "CodeCompanionRequestFinished",
    group = group,
    callback = function(request)
      local handle = M.spinner:pop_progress_handle(request.data.id)
      if handle then
        M.spinner:report_exit_status(handle, request)
        handle:finish()
      end
    end,
  })
end

M.spinner.handles = {}

function M.spinner:store_progress_handle(id, handle)
  M.spinner.handles[id] = handle
end

function M.spinner:pop_progress_handle(id)
  local handle = M.spinner.handles[id]
  M.spinner.handles[id] = nil
  return handle
end

function M.spinner:create_progress_handle(request)
  return progress.handle.create({
    title = " Requesting assistance (" .. request.data.interaction .. ")",
    message = "In progress...",
    lsp_client = {
      name = M.spinner:llm_role_title(request.data.adapter),
    },
  })
end

function M.spinner:llm_role_title(adapter)
  local parts = {}
  table.insert(parts, adapter.formatted_name)
  if adapter.model and adapter.model ~= "" then
    table.insert(parts, "(" .. adapter.model .. ")")
  end
  return table.concat(parts, " ")
end

function M.spinner:report_exit_status(handle, request)
  if request.data.status == "success" then
    handle.message = "Completed"
  elseif request.data.status == "error" then
    handle.message = " Error"
  else
    handle.message = "󰜺 Cancelled"
  end
end

return M
