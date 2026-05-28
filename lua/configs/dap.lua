local dap = require("dap")
local dapui = require("dapui")

dapui.setup()

dap.listeners.before.attach.dapui_config = function()
  dapui.open()
end

dap.listeners.before.launch.dapui_config = function()
  dapui.open()
end

dap.listeners.before.event_terminated.dapui_config = function()
  dapui.close()
end

dap.listeners.before.event_exited.dapui_config = function()
  dapui.close()
end

local dap = require("dap")

local extension_path = vim.fn.stdpath("data")
  .. "\\mason\\packages\\codelldb\\extension\\"

local codelldb_path = extension_path .. "adapter\\codelldb.exe"
local liblldb_path = extension_path .. "lldb\\bin\\liblldb.dll"

dap.adapters.codelldb = {
  type = "server",
  port = "${port}",
  executable = {
    command = codelldb_path,
    args = { "--port", "${port}" },
  },
}
dap.configurations.c = {
  {
    name = "Launch C",
    type = "codelldb",
    request = "launch",

    program = function()
      return vim.fn.input(
        "Executable: ",
        vim.fn.getcwd() .. "\\build\\win32-software-renderer.exe",
        "file"
      )
    end,

    cwd = vim.fn.getcwd(),
    stopOnEntry = false,
  },
}

dap.configurations.cpp = dap.configurations.c
