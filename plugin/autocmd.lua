vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "Highlight when yanking text",
  group = vim.api.nvim_create_augroup("highlight-yank", { clear = true }),
  callback = function()
    vim.hl.on_yank()
  end,
})

local sensitive_path_patterns = vim.tbl_map(function(pattern)
  local expanded_pattern = pattern:gsub("^~", vim.fn.expand("~"), 1)
  return vim.fn.glob2regpat(expanded_pattern)
end, {
  "/tmp/*",
  "/dev/shm/*",
  "/run/secrets/*",
  "*.env",
  "*.pem",
  "*secret*",
  "*Secret*",
  "*vault*",
  "*Vault*",
  "~/.ssh/*",
  "~/.kube/*",
  "~/.gnupg/*",
  "~/.local/share/gnupg/*",
})

local function is_sensitive_path(path)
  if path == "" then
    return false
  end

  local absolute_path = vim.fn.fnamemodify(path, ":p")

  for _, pattern in ipairs(sensitive_path_patterns) do
    if vim.fn.match(absolute_path, pattern) >= 0 then
      return true
    end
  end

  return false
end

vim.api.nvim_create_autocmd({ "BufReadPre", "BufNewFile", "BufFilePost" }, {
  desc = "Disable persistent file artifacts for sensitive paths",
  group = vim.api.nvim_create_augroup("sensitive-paths", { clear = true }),
  callback = function(args)
    if not is_sensitive_path(args.file) then
      return
    end

    vim.opt_local.undofile = false
    vim.opt_local.swapfile = false
    vim.opt_local.backup = false
    vim.opt_local.writebackup = false
  end,
})
