local ls = require("luasnip")
print("luasnip config loaded")
require("luasnip.loaders.from_lua").load({
  paths = vim.fn.stdpath("config") .. "/lua/snippets",
})
