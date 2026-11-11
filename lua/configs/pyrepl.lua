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

-- Returns the output lines of the last executed command in the REPL
M.last_output = function()
  if not (buf and vim.api.nvim_buf_is_valid(buf)) then
    return nil
  end
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- drop trailing empty terminal lines
  while #lines > 0 and lines[#lines]:match "^%s*$" do
    table.remove(lines)
  end

  -- find the last two prompts (">>> ")
  local prompts = {}
  for i = #lines, 1, -1 do
    if lines[i]:match "^>>>" then
      table.insert(prompts, i)
      if #prompts == 2 then
        break
      end
    end
  end
  if #prompts < 2 then
    return nil
  end
  local stop, start = prompts[1], prompts[2] + 1
  -- skip multi-line input continuation lines ("... ")
  while start < stop and lines[start]:match "^%.%.%." do
    start = start + 1
  end
  if start >= stop then
    return nil
  end
  return vim.list_slice(lines, start, stop - 1)
end

M.paste_last_output = function()
  local out = M.last_output()
  if not out then
    vim.notify("PyRepl: no output found", vim.log.levels.WARN)
    return
  end
  vim.api.nvim_put(out, "l", true, true)
end

return M
