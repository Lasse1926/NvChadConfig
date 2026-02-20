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
