local function sensitive_buffer()
  local bufnr = vim.api.nvim_get_current_buf()
  local name = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.bo[bufnr].filetype

  if filetype == "dotenv" or filetype == "gpg" then
    return true
  end

  local path = name ~= "" and vim.fs.normalize(name) or ""
  if path == "" then
    return false
  end

  local patterns = {
    "/tmp/*",
    "/dev/shm/*",
    "/run/secrets/*",
    "*.env",
    "*.env.*",
    "*.pem",
    "*.key",
    "*.crt",
    "*.p12",
    "*.pfx",
    "*.asc",
    "*.gpg",
    "*.age",
    "*secret*",
    "*Secret*",
    "*secrets*",
    "*Secrets*",
    "*vault*",
    "*Vault*",
    vim.fs.normalize("~/.ssh/*"),
    vim.fs.normalize("~/.kube/*"),
    vim.fs.normalize("~/.gnupg/*"),
    vim.fs.normalize("~/.local/share/gnupg/*"),
  }

  for _, pattern in ipairs(patterns) do
    if vim.fn.match(path, vim.fn.glob2regpat(pattern)) >= 0 then
      return true
    end
  end

  return false
end

local function request_virtualtext()
  if sensitive_buffer() then
    vim.notify("Minuet blocked for sensitive buffer", vim.log.levels.WARN, { title = "Minuet" })
    return
  end

  require("minuet.virtualtext").action.next()
end

return {
  {
    "milanglacier/minuet-ai.nvim",
    cmd = "Minuet",
    event = "InsertEnter",
    keys = {
      { "<leader>ii", "<Cmd>Minuet virtualtext toggle<CR>", desc = "Minuet: Toggle virtual text" },
    },
    config = function()
      require("minuet").setup({
        provider = "openai_fim_compatible",
        context_window = 9000,
        context_ratio = 0.67,
        throttle = 1000,
        debounce = 350,
        request_timeout = 20,
        notify = "warn",
        n_completions = 1,
        enable_predicates = {
          function()
            return not sensitive_buffer()
          end,
        },
        virtualtext = {
          auto_trigger_ft = { "*" },
          keymap = {
            accept = "<C-a>",
            accept_line = "<S-Tab>",
            dismiss = "<C-]>",
          },
        },
        provider_options = {
          openai_fim_compatible = {
            api_key = "DEEPSEEK_API_KEY",
            name = "DeepSeek",
            end_point = "https://api.deepseek.com/beta/completions",
            model = "deepseek-v4-pro",
            stream = false,
            optional = {
              max_tokens = 96,
              temperature = 0,
            },
          },
        },
      })

      vim.keymap.set("i", "<C-g>", request_virtualtext, { desc = "Minuet: Request completion" })
    end,
  },
}
