local M = {}

function M.setup()
  require("pandoc").setup({
    default = {
      output = "%s.html",
      args = {
        {"--standalone"},
        {"--toc"},
      },
    },
  })

  -- HTML build (vimhtml.yaml)
  vim.keymap.set("n", "<leader>ph", function()
    local file = vim.fn.expand("%:p")
    local dir = vim.fn.expand("%:p:h")
    local css = dir .. "/style.css"

    vim.fn.jobstart({
      "pandoc",
      file,
      "--defaults=vimhtml.yaml",
      "--css", css,
      "--output", file:gsub("%.md$", ".html"),
      "-s",
    }, { detach = true })
  end, { desc = "Pandoc → HTML (vimhtml.yaml)" })

  -- Slides build (slides.yaml + revealjs)
  vim.keymap.set("n", "<leader>ps", function()
    local file = vim.fn.expand("%:p")
    local out = file:gsub("%.md$", ".html")
    local dir = vim.fn.expand("%:p:h")
    local css = dir .. "/style.css"

    vim.fn.jobstart({
      "pandoc",
      file,
      "--defaults=slides.yaml",
      "-t", "revealjs",
      "--css", css,
      "--output", out,
      "-s",
    }, { detach = true })
  end, { desc = "Pandoc → Slides (revealjs)" })
end

M.setup()

return M
