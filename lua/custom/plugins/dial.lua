return {
  {
    "monaqa/dial.nvim",
    keys = {
      {
        "<C-c>",
        function()
          require("dial.map").manipulate("increment", "normal")
        end,
        desc = "Dial: Increment",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manipulate("decrement", "normal")
        end,
        desc = "Dial: Decrement",
      },
      {
        "g<C-c>",
        function()
          require("dial.map").manipulate("increment", "gnormal")
        end,
        desc = "Dial: Increment (gnormal)",
      },
      {
        "g<C-x>",
        function()
          require("dial.map").manipulate("decrement", "gnormal")
        end,
        desc = "Dial: Decrement (gnormal)",
      },
      {
        "<C-c>",
        function()
          require("dial.map").manipulate("increment", "visual")
        end,
        desc = "Dial: Increment (visual)",
        mode = "v",
      },
      {
        "<C-x>",
        function()
          require("dial.map").manipulate("decrement", "visual")
        end,
        desc = "Dial: Decrement (visual)",
        mode = "v",
      },
      {
        "g<C-c>",
        function()
          require("dial.map").manipulate("increment", "gvisual")
        end,
        desc = "Dial: Increment (gvisual)",
        mode = "v",
      },
      {
        "g<C-x>",
        function()
          require("dial.map").manipulate("decrement", "gvisual")
        end,
        desc = "Dial: Decrement (gvisual)",
        mode = "v",
      },
    },
    config = function()
      local augend = require("dial.augend")
      require("dial.config").augends:register_group({
        default = {
          augend.integer.alias.decimal,
          augend.integer.alias.hex,
          augend.constant.alias.bool,
          augend.semver.alias.semver,
          augend.date.alias["%d/%m/%Y"],
          augend.date.alias["%Y-%m-%d"],
          augend.date.alias["%m/%d"],
          augend.date.alias["%H:%M"],
          augend.constant.new({
            elements = { "on", "off" },
            word = true,
          }),
        },
        visual = {
          augend.constant.alias.alpha,
          augend.constant.alias.Alpha,
        },
      })
    end,
  },
}
