local M = {}

local function css_arg_if_exists(css_path)
  if vim.loop.fs_stat(css_path) then
    return { "--css", css_path }
  end
  return {}
end

function M.setup()
  require("pandoc").setup({
    default = {
      output = "%s.html",
      args = {
        { "--standalone" },
        { "--toc" },
      },
    },
  })

  -- HTML build (vimhtml.yaml)
  vim.keymap.set("n", "<leader>ph", function()
    local file = vim.fn.expand("%:p")
    local dir = vim.fn.expand("%:p:h")
    local css = dir .. "/style.css"

    local cmd = {
      "pandoc",
      file,
      "--defaults=vimhtml.yaml",
      "--output", file:gsub("%.md$", ".html"),
      "-s",
    }

    vim.list_extend(cmd, css_arg_if_exists(css))

    vim.fn.jobstart(cmd, { detach = true })
  end, { desc = "Pandoc → HTML (vimhtml.yaml)" })

  -- Slides build (slides.yaml + revealjs)
  vim.keymap.set("n", "<leader>ps", function()
    local file = vim.fn.expand("%:p")
    local out = file:gsub("%.md$", ".html")
    local dir = vim.fn.expand("%:p:h")
    local css = dir .. "/style.css"

    local cmd = {
      "pandoc",
      file,
      "--defaults=slides.yaml",
      "-t", "revealjs",
      "--output", out,
      "-s",
    }

    vim.list_extend(cmd, css_arg_if_exists(css))

    vim.fn.jobstart(cmd, { detach = true })
  end, { desc = "Pandoc → Slides (revealjs)" })
end

M.setup()

return M
