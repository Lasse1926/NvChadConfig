require("nvchad.configs.lspconfig").defaults()
local base = require("nvchad.configs.lspconfig")

local on_attach = base.on_attach
local capabilities = base.capabilities

local lspconfig = require("lspconfig")

lspconfig.clangd.setup{
  on_attach = function(client,bufnr)
    client.server_capabilities.signatureHelpProvider = false
    on_attach(client,bufnr)
  end,
  capabilities = capabilities,
}

lspconfig.ts_ls.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})

lspconfig.eslint.setup({
  on_attach = on_attach,
  capabilities = capabilities,
})


local servers = { "html", "cssls" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
