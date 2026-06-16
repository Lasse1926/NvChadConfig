require("nvchad.configs.lspconfig").defaults()
local base = require("nvchad.configs.lspconfig")

local userprofile = vim.env.USERPROFILE

local on_attach = base.on_attach
local capabilities = base.capabilities

vim.lsp.config("clangd",{
  on_attach = function(client,bufnr)
    client.server_capabilities.signatureHelpProvider = false
    on_attach(client,bufnr)
  end,
  capabilities = capabilities,
  cmd = { "clangd", "--compile-commands-dir=build" }, --Tells clangd to read build/compile_commands.json for proper header and flag info
})

vim.lsp.config("ts_ls",{
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.config("pyright", {
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.config("eslint",{
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.config("rust_analyzer",{
  cmd = { "rustup", "run", "nightly", "rust-analyzer" },
})
vim.lsp.config("phpactor",{
    on_attach = on_attach,
    init_options = {
        ["language_server_phpstan.enabled"] = false,
        ["language_server_psalm.enabled"] = false,
    }
})

vim.lsp.config("gdscript", {
  cmd = { "ncat", "127.0.0.1", "6005" },
  filetypes = { "gd", "gdscript", "gdshader" },
  root_markers = { "project.godot", ".git" },
})

vim.lsp.enable("gdscript")

vim.lsp.config("ols", {
  cmd = {
    userprofile .. "/.lsp/ols/ols-x86_64-pc-windows-msvc.exe",
  },
  mason = false,
  settings = {
    odin_command = userprofile .. "/.odin/odin.exe",
  },
})

local servers = { "html", "cssls", "pyright","ols" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
