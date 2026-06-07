local subheaders = {
  "Don't remember signatures? Shift-K or Ctrl-H",
  "ZZ",
  "May the code be with you!",
  "AI-powered technical debt machine",
  "Feeling down? You're not alone!",
  "Be well, be safe, and be happy!",
  "Byte-sized joy, one motion at a time.",
  "PDE, PDE, PDE!",
  "I use arch, btw",
  "Terminal wizardry",
  "Dis' is nothin' but a lua script.",
  "Some can C, a few C sharp — but only a handful C plus-plus.",
  "Welcome back. No, you still don't need Emacs.",
  "TODO: Fix everything",
  "Trust the muscle memory.",
  "Save early, save often.",
  "Make small changes, but make them relentlessly.",
  "Live, laugh, :wq",
  "Another config tweak? Groundbreaking.",
  "Big plans, huh? Let's see how long that lasts.",
  "Home is where the init.lua is",
  "You had me at :help",
  "The real code was the typos we made along the way.",
  "Congratulations — you broke Vim again! Productivity just skyrocketed.",
  "One more plugin won't hurt, right?",
  "Another plugin? Sure — because what you really need is more chaos in your life.",
  "Someday your code will compile. Or the universe will collapse. Either way, exciting times.",
  "Proudly writing tomorrow's legacy code today.",
  "The bravest soldiers run nightly.",
  "You don't need motivation. You need coffee.",
  "Whitespace wars: the saga continues.",
  "Remember: nothing is truly deprecated, only forgotten.",
  "Fork it!",
}

local function get_header()
  local ascii = require("custom.ascii")
  local subheader = subheaders[math.random(#subheaders)]
  local header_tbl = ascii.get_random_global() or { "lol it broke" }
  return table.concat(header_tbl, "\n") .. "\n" .. subheader
end

local starter = require("mini.starter")
local startup_ms

local function get_startup_ms()
  if startup_ms then
    return startup_ms
  end

  if vim.g.custom_start_time then
    return (vim.uv.hrtime() - vim.g.custom_start_time) / 1e6
  end
end

vim.api.nvim_create_autocmd("VimEnter", {
  once = true,
  callback = function()
    startup_ms = get_startup_ms()
    if _G.MiniStarter and vim.bo.filetype == "ministarter" then
      MiniStarter.refresh()
    end
  end,
})

local items = {
  starter.sections.builtin_actions(),
  starter.sections.recent_files(5, true),
  {
    name = "Oil",
    action = "Oil",
    section = "Custom",
  },
  {
    name = "Scratch",
    action = "Scratch",
    section = "Custom",
  },
  {
    name = "Find files",
    action = "lua require('fzf-lua').files()",
    section = "Custom",
  },
  {
    name = "Grep",
    action = "lua require('fzf-lua').live_grep()",
    section = "Custom",
  },
  {
    name = "Config",
    action = "lua require('fzf-lua').files({ cwd = require('custom.runtime').config_root() })",
    section = "Custom",
  },
}

local function get_footer()
  local ok, summary = pcall(function()
    return require("custom.pack.loader").summary()
  end)
  local version = vim.version()
  local startuptime = ""

  local ms = get_startup_ms()
  if ms then
    startuptime = (" in %.2fms"):format(ms)
  end

  if not ok then
    return (" Neovim %d.%d.%d%s"):format(version.major, version.minor, version.patch, startuptime)
  end

  local ambient = summary.ambient_start > 0 and (" + %d start packages"):format(summary.ambient_start) or ""

  return (" Neovim %d.%d.%d loaded %d/%d plugins%s%s"):format(
    version.major,
    version.minor,
    version.patch,
    summary.loaded,
    summary.total,
    ambient,
    startuptime
  )
end

vim.keymap.set("n", "<leader>S", "<cmd>lua require('mini.starter').open()<CR>", { desc = "Open starter" })

return {
  evaluate_single = true,
  header = get_header,
  items = items,
  footer = get_footer,
}
