**This repo is My custom NvChad Config**

# Use

use git Clone to clone this repo into into the same config folder as the nvim folder.

the use this command to Clone Repo with nvim name to replace the old config

delete old nvim folder

git clone https://github.com/Lasse1926/NvChadConfig.git nvim

Then Run MasonInstallAll to ensure LSP are installed

## VimWiki

add private wiki paths inside lua/configs/local.lua
```
vim.g.vimwiki_list = {
  {
    path = vim.fn.expand("~/vimwiki/"),
    syntax = "markdown",
    ext = ".md",
  },
  {
    path = vim.fn.expand("Path/to/Wiki"),
    syntax = "markdown",
    ext = ".md",
    name = "NewWiki",
  },
}
```

# Credits

1) Lazyvim starter https://github.com/LazyVim/starter as nvchad's starter was inspired by Lazyvim's . It made a lot of things easier!
2) NvChad as a base for my Nvim config https://github.com/NvChad/NvChad
