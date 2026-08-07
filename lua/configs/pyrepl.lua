local M = {}

local buf = nil

local function float_opts()
  local float = require("nvconfig").term.float
  local o = vim.o
  return {
    relative = "editor",
    row = math.ceil(float.row * o.lines),
    col = math.ceil(float.col * o.columns),
    width = math.ceil(float.width * o.columns),
    height = math.ceil(float.height * o.lines),
    border = float.border,
  }
end

local function display()
  local win = vim.api.nvim_open_win(buf, true, float_opts())
  vim.bo[buf].buflisted = false
  vim.bo[buf].ft = "NvTerm_float"
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
end

local function create()
  buf = vim.api.nvim_create_buf(false, true)
  display()
  vim.fn.termopen({ "python" }, { detach = false })
end

M.toggle = function()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    local winid = vim.fn.bufwinid(buf)
    if winid ~= -1 then
      vim.api.nvim_win_close(winid, true)
      return
    end
    display()
  else
    create()
  end
  vim.cmd "startinsert"
end

return M
