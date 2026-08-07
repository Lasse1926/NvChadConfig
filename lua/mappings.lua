require "nvchad.mappings"


local map = vim.keymap.set

map("n", ";", ":", { desc = "Cmd | Enter command mode" })
map("i", "jk", "<ESC>", { desc = "Insert | Exit insert mode" })

local opts = { noremap = true, silent = true }
-- Show hover
map("n", "K", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Lsp | Hover" }))

-- Jump to definition
map("n", "gd", vim.lsp.buf.definition, vim.tbl_extend("force", opts, { desc = "Lsp | Go to Definition" }))

-- Open code actions using the default LSP UI
map("n", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Lsp | Code Action" }))

-- Open code actions for the selected visual range
map("x", "<leader>ca", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Lsp | Code Action" }))
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")

map("n", "<leader>yp",
function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end,
{ desc = "File | Copy relative path", noremap = true, silent = true })

map("n","<leader>le",
function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
  vim.opt_local.spelllang = "en_us"
end,{ desc = "Spell | Toggle English" })

map("n","<leader>lg",
function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
  vim.opt_local.spelllang = "de_20"
end,{ desc = "Spell | Toggle German" })

map("v", "<leader>lg", function()
  vim.cmd('normal! "zy')
  vim.cmd("grep! " .. vim.fn.escape(vim.fn.getreg("z"), [[\ /]]))
end, { desc = "Spell | Grep selected text" })

local dap = require("dap")
local dapui = require("dapui")

-- Core controls
map("n", "<leader>dc", dap.continue, { desc = "Dap | Continue" })
map("n", "<leader>do", dap.step_over, { desc = "Dap | Step Over" })
map("n", "<leader>di", dap.step_into, { desc = "Dap | Step Into" })
map("n", "<leader>dO", dap.step_out, { desc = "Dap | Step Out" })

-- Breakpoints
map("n", "<leader>db", dap.toggle_breakpoint, { desc = "Dap | Toggle Breakpoint" })
map("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "Dap | Conditional Breakpoint" })

-- UI
map("n", "<leader>du", dapui.toggle, { desc = "Dap | Toggle UI" })
map("n", "<leader>de", dapui.eval, { desc = "Dap | Evaluate Expression" })
map("n", "<leader>dr", dap.repl.open, { desc = "Dap | Open REPL" })

-- Session control
map("n", "<leader>dt", function()
  dap.terminate()
  dapui.close()
end, { desc = "Dap | Terminate" })

-- Utilities
map("n", "<leader>dl", dap.run_last, { desc = "Dap | Run Last" })

map({ "n", "v" }, "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "Dap | Hover Variables" })
