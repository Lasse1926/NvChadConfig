require "nvchad.mappings"


local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

local opts = { noremap = true, silent = true }
-- Show hover
map("n", "K", vim.lsp.buf.hover, opts)

-- Jump to definition
map("n", "gd", vim.lsp.buf.definition, opts)

-- Open code actions using the default LSP UI
map("n", "<leader>ca", vim.lsp.buf.code_action, opts)

-- Open code actions for the selected visual range
map("x", "<leader>ca", vim.lsp.buf.code_action, opts)
-- map({ "n", "i", "v" }, "<C-s>", "<cmd> w <cr>")
local nvtree = require("configs.nvimtree")

map("n", "<leader>ie", nvtree.open_in_explorer, { desc = "Open folder in Explorer", noremap = true, silent = true })
map("n", "<leader>yp",
function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end,
{ desc = "Yank file path (relative to cwd)", noremap = true, silent = true })

map("n","<leader>le",
function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
  vim.opt_local.spelllang = "en_us"
end,{ desc = "toggel english spellcheck" })

map("n","<leader>lg",
function()
  vim.opt_local.spell = not vim.opt_local.spell:get()
  vim.opt_local.spelllang = "de_20"
end,{ desc = "enable german spellcheck" })

map("v", "<leader>lg", function()
  vim.cmd('normal! "zy')
  vim.cmd("grep! " .. vim.fn.escape(vim.fn.getreg("z"), [[\ /]]))
end, { desc = "grep selected text" })

local dap = require("dap")
local dapui = require("dapui")

-- Core controls
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step Out" })

-- Breakpoints
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
  dap.set_breakpoint(vim.fn.input("Condition: "))
end, { desc = "Conditional Breakpoint" })

-- UI
vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle UI" })
vim.keymap.set("n", "<leader>de", dapui.eval, { desc = "Evaluate Expression" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })

-- Session control
vim.keymap.set("n", "<leader>dt", function()
  dap.terminate()
  dapui.close()
end, { desc = "Terminate" })

-- Utilities
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })

vim.keymap.set({ "n", "v" }, "<leader>dh", function()
  require("dap.ui.widgets").hover()
end, { desc = "Hover Variables" })
