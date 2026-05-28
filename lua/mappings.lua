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
