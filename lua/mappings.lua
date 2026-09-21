require "nvchad.mappings"


local map = vim.keymap.set

-- Fzf-lua: overrides the telescope maps set by `require "nvchad.mappings"`.
-- Kept up here rather than at the bottom on purpose -- the top-level
-- require("dap") further down would abort this file if dap ever failed to load,
-- and that would leave NvChad's <cmd>Telescope ...<CR> maps dangling with E492.
map("n", "<leader>ff", "<cmd>FzfLua files<CR>", { desc = "Find | Files" })
map(
  "n",
  "<leader>fa",
  "<cmd>FzfLua files follow=true no_ignore=true hidden=true<CR>",
  { desc = "Find | All files" }
)
map("n", "<leader>fw", "<cmd>FzfLua live_grep<CR>", { desc = "Find | Live grep" })
map("n", "<leader>fb", "<cmd>FzfLua buffers<CR>", { desc = "Find | Buffers" })
map("n", "<leader>fh", "<cmd>FzfLua helptags<CR>", { desc = "Find | Help tags" })
map("n", "<leader>fo", "<cmd>FzfLua oldfiles<CR>", { desc = "Find | Old files" })
map("n", "<leader>fz", "<cmd>FzfLua blines<CR>", { desc = "Find | Lines in buffer" })
map("n", "<leader>ma", "<cmd>FzfLua marks<CR>", { desc = "Find | Marks" })
map("n", "<leader>cm", "<cmd>FzfLua git_commits<CR>", { desc = "Git | Commits" })
map("n", "<leader>gt", "<cmd>FzfLua git_status<CR>", { desc = "Git | Status" })
map("n", "<leader>pt", function()
  require("configs.fzfterms").pick()
end, { desc = "Find | Hidden terminals" })

-- LSP pickers. Lowercase = current buffer, uppercase = whole project.
map("n", "<leader>fs", "<cmd>FzfLua lsp_document_symbols<CR>", { desc = "Lsp | Symbols in file" })
map("n", "<leader>fS", "<cmd>FzfLua lsp_live_workspace_symbols<CR>", { desc = "Lsp | Symbols in project" })
map("n", "<leader>fr", "<cmd>FzfLua lsp_references<CR>", { desc = "Lsp | References" })
map("n", "<leader>fR", "<cmd>FzfLua lsp_finder<CR>", { desc = "Lsp | Finder (refs/defs/impls)" })
map("n", "<leader>fe", "<cmd>FzfLua lsp_document_diagnostics<CR>", { desc = "Lsp | Diagnostics in file" })
map("n", "<leader>fE", "<cmd>FzfLua lsp_workspace_diagnostics<CR>", { desc = "Lsp | Diagnostics in project" })
-- Parser-based, so this one still works with no language server attached.
map("n", "<leader>ft", "<cmd>FzfLua treesitter<CR>", { desc = "Find | Treesitter symbols" })
-- Deliberately not overridden:
--   <leader>fm -> conform format file (never was telescope)
--   <leader>th -> require("nvchad.themes").open() (volt picker, not telescope)

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

-- Registers <leader>ie (open file/folder in system default / Explorer)
require "configs.nvimtree"

map("n", "<leader>yr",
function()
  local path = vim.fn.expand("%:.")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end,
{ desc = "File | Copy relative path", noremap = true, silent = true })

map("n", "<leader>yp",
function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  print("Copied: " .. path)
end,

{ desc = "File | Copy absolute path", noremap = true, silent = true })
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

vim.api.nvim_create_user_command("PyRepl", function()
  require("configs.pyrepl").toggle()
end, { desc = "Python | Toggle REPL" })

map({ "n", "t" }, "<A-p>", "<cmd>PyRepl<CR>", { desc = "Python | Toggle REPL" })

-- Gitsigns
map({"n"},"<leader>gd",function ()
  require('gitsigns').diffthis()
end,{ desc = "Git | Diffthis" })

map({"n"},"<leader>gh",function ()
  require('gitsigns').preview_hunk_inline()
end,{ desc = "Git | preview hunk inline" })

-- Diff
vim.api.nvim_create_user_command("DiffPick", function()
  require("configs.filediff").pick_and_diff()
end, { desc = "File | Diff against picked file" })

map("n", "<leader>fd", "<cmd>DiffPick<CR>", { desc = "File | Diff against picked file" })

map("n", "<C-c>", "<Nop>", { desc = "Disable Ctrl-C" })
