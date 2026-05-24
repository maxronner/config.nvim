local M = {}

M.defaults = {
  enabled = true,
  auto = true,
  debounce_ms = 350,
  min_prefix_chars = 8,
  prefix_chars = 6000,
  suffix_chars = 3000,
  max_completion_chars = 1200,
  accept_all_key = "<C-a>",
  accept_forward_key = "<S-Tab>",
  dismiss_key = "<C-]>",
  manual_key = "<C-g>",
  manual_normal_key = "<leader>ii",
  toggle_key = "<leader>iq",
  highlight = "Comment",
  provider = {
    name = "deepseek",
    api_key_env = "DEEPSEEK_API_KEY",
    base_url = "https://api.deepseek.com/beta",
    model = "deepseek-v4-pro",
    max_tokens = 96,
    temperature = 0.0,
    timeout = 20,
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

return M
