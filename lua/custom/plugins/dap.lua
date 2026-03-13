return {
  {
    "mfussenegger/nvim-dap",
    keys = {
      { "<leader>bt", function() require("dap").toggle_breakpoint() end, desc = "DAP: Toggle Breakpoint" },
      { "<F6>",       function() require("dap").run_to_cursor() end,     desc = "DAP: Run to Cursor" },
      { "<leader>?",  function() require("dapui").eval(nil, { enter = true }) end, desc = "DAP: Eval under cursor" },
      { "<F1>",       function() require("dap").continue() end,          desc = "DAP: Continue" },
      { "<F2>",       function() require("dap").step_into() end,         desc = "DAP: Step Into" },
      { "<F3>",       function() require("dap").step_over() end,         desc = "DAP: Step Over" },
      { "<F4>",       function() require("dap").step_out() end,          desc = "DAP: Step Out" },
      { "<F5>",       function() require("dap").step_back() end,         desc = "DAP: Step Back" },
      { "<F13>",      function() require("dap").restart() end,           desc = "DAP: Restart" },
    },
    dependencies = {
      "leoluz/nvim-dap-go",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "williamboman/mason.nvim",
    },
    config = function()
      local dap = require("dap")
      local ui = require("dapui")

      require("dapui").setup()
      require("dap-go").setup()

      dap.listeners.before.attach.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        ui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        ui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        ui.close()
      end
    end,
  },
}
