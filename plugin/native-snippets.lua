vim.api.nvim_create_user_command("Snippet", function(ctx)
  require("custom.native_snippets").expand(ctx.args)
end, {
  nargs = 1,
  complete = function()
    return require("custom.native_snippets").names()
  end,
  desc = "Expand a native snippet",
})
