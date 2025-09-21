require("nvchad.configs.lspconfig").defaults()
local base = require("nvchad.configs.lspconfig")


local on_attach = base.on_attach
local capabilities = base.capabilities


vim.lsp.config("clangd",{
  on_attach = function(client,bufnr)
    client.server_capabilities.signatureHelpProvider = false
    on_attach(client,bufnr)
  end,
  capabilities = capabilities,
})
vim.lsp.config("ts_ls",{
  on_attach = on_attach,
  capabilities = capabilities,
})

vim.lsp.config("eslint",{
  on_attach = on_attach,
  capabilities = capabilities,
})


local servers = { "html", "cssls" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
