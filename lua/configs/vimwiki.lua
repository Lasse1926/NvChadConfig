local M = {}

local wiki_path = vim.fn.expand("~/vimwiki")

local function get_nvimtree_api()
  local ok, api = pcall(require, "nvim-tree.api")
  if ok then
    return api
  end
end

local function normalize(path)
  return vim.fs.normalize(path)
end

local function set_root(path)
  vim.cmd("cd " .. path)

  local api = get_nvimtree_api()
  if api then
    api.tree.change_root(path)
  end
end

function M.open_wiki()
  set_root(wiki_path)
  vim.cmd("edit " .. wiki_path .. "/index.md")
end

function M.open_project()
  local project_path = vim.fn.getcwd()

  set_root(project_path)

  local api = get_nvimtree_api()
  if api then
    api.tree.reload()
  end
end

function M.setup()
  vim.keymap.set("n", "<leader>ww", M.open_wiki, { desc = "Wiki workspace" })
  vim.keymap.set("n", "<leader>wt", M.open_project, { desc = "Project workspace" })

  local last_state = nil

  vim.api.nvim_create_autocmd({ "BufEnter", "BufWinEnter" }, {
    callback = function()
      local file = vim.api.nvim_buf_get_name(0)
      if file == "" then return end

      file = normalize(file)
      local wiki = normalize(wiki_path)

      if file:sub(1, #wiki) == wiki then
        if last_state ~= "wiki" then
          last_state = "wiki"
          set_root(wiki)
        end
      else
        if last_state ~= "project" then
          last_state = "project"
          set_root(vim.fn.getcwd())
        end
      end
    end,
  })
end

return M
