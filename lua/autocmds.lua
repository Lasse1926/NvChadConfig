require "nvchad.autocmds"
local autocmd = vim.api.nvim_create_autocmd

-- luasnip cleanup (keep as is)
autocmd("InsertLeave", {
  callback = function()
    if require("luasnip").session.current_nodes[vim.api.nvim_get_current_buf()]
      and not require("luasnip").session.jump_active then
      require("luasnip").unlink_current()
    end
  end,
})

-- Tell Vimwiki to allow custom folds
vim.g.vimwiki_folding = "custom"

-- Apply folding for Markdown and Vimwiki
autocmd("FileType", {
  pattern = { "markdown", "vimwiki" },
  callback = function()
    vim.opt_local.foldmethod = "expr"
    vim.opt_local.foldexpr = "v:lua.require'markdown_folds'.foldexpr(v:lnum)"
    vim.opt_local.foldlevel = 99
    vim.opt_local.foldenable = true
  end,
})
