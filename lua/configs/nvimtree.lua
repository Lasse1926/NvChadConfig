local M = {}
local ok, api = pcall(require, "nvim-tree.api")
if not ok then return M end

function M.open_in_explorer()
  local node = nil -- nil = automatically use node under cursor
  if vim.bo.filetype == "NvimTree" then
    api.node.run.system(node)
  else
    -- fallback for normal buffers
    local path = vim.fn.expand("%:p")
    if vim.fn.isdirectory(path) == 0 then
      path = vim.fn.fnamemodify(path, ":h")
    end
    vim.fn.jobstart({ "explorer", path }, { detach = true })
  end
end

-- Mapping
vim.keymap.set("n", "<leader>ie", M.open_in_explorer, { desc = "Open folder in Explorer", noremap = true, silent = true })

return M
