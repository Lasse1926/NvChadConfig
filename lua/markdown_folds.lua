local M = {}

-- Helper: find nearest heading level above current line
local function nearest_heading_level(lnum)
  for i = lnum - 1, 1, -1 do
    local line = vim.fn.getline(i)
    local heading = line:match("^(#+)")
    if heading then
      return #heading
    end
  end
  return 1 -- default if none found
end

function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)

  -- YAML front matter
  if line:match("^---%s*$") then
    if lnum == 1 or vim.fn.getline(lnum - 1):match("^---%s*$") then
      return ">1"
    else
      return "<1"
    end
  end

  -- Code fences (``` or ~~~)
  if line:match("^%s*```") or line:match("^%s*~~~") then
    local level = nearest_heading_level(lnum)
    return ">" .. (level + 1)
  end

  -- Headings
  local heading = line:match("^(#+)")
  if heading then
    return ">" .. tostring(#heading)
  end

  -- Lists (-, *, +, or numbered)
  if line:match("^%s*[-*+]%s+") or line:match("^%s*%d+[.)]%s+") then
    local level = nearest_heading_level(lnum)
    return ">" .. (level + 1)
  end

  return "="
end

return M
