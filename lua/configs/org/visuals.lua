-- Org heading visuals:
--   * per-level heading colors + full-width tinted bars, built from the
--     NvChad/base46 theme palette (bright text on a faint tint of that color)
--   * folded headings get a slightly stronger tint so you can tell them apart
--   * folds don't swallow the blank lines right before the next heading
-- Wired up in: lua/configs/org/orgmode.lua (setup) and after/ftplugin/org.lua (attach)
-- Markdown (render-markdown) is intentionally NOT changed.

local M = {}

-- base46 palette key per heading level (levels 7+ reuse the last one).
local LEVEL_COLORS = { "purple", "cyan", "green", "orange", "baby_pink", "nord_blue" }
-- Fallbacks if base46 isn't available (eldritch values).
local FALLBACK = {
  black = "#171928",
  purple = "#A48CF2",
  cyan = "#04D1F9",
  green = "#37F499",
  orange = "#F7C67F",
  baby_pink = "#F265B5",
  nord_blue = "#7081D0",
}
-- How much of the heading color is mixed into the background (0..1).
local BAR_MIX = 0.15 -- open heading bar
local FOLD_MIX = 0.25 -- folded heading bar

local ns = vim.api.nvim_create_namespace "org_visuals"

local function heading_level(line)
  local stars = line:match "^(%*+)%s" or line:match "^(%*+)$"
  return stars and #stars or nil
end

-- ---------------------------------------------------------------- colors ---

local function palette()
  local ok, base46 = pcall(require, "base46")
  local p = ok and base46.get_theme_tb and base46.get_theme_tb "base_30" or nil
  return setmetatable({}, {
    __index = function(_, k)
      return (p and p[k]) or FALLBACK[k]
    end,
  })
end

-- Mix `amount` (0..1) of hex color `a` into hex color `b`.
local function mix(a, b, amount)
  local function rgb(hex)
    hex = hex:gsub("#", "")
    return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
  end
  local r1, g1, b1 = rgb(a)
  local r2, g2, b2 = rgb(b)
  local function c(x, y)
    return math.floor(x * amount + y * (1 - amount) + 0.5)
  end
  return string.format("#%02x%02x%02x", c(r1, r2), c(g1, g2), c(b1, b2))
end

local function set_highlights()
  local p = palette()
  local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local base = normal_bg and string.format("#%06x", normal_bg) or p.black
  for n = 1, 8 do
    local color = p[LEVEL_COLORS[math.min(n, #LEVEL_COLORS)]]
    vim.api.nvim_set_hl(0, "@org.headline.level" .. n, { fg = color, bold = true })
    vim.api.nvim_set_hl(0, "OrgHeadingBg" .. n, { bg = mix(color, base, BAR_MIX) })
    vim.api.nvim_set_hl(0, "OrgHeadingFold" .. n, { fg = color, bg = mix(color, base, FOLD_MIX), bold = true })
  end
end

-- ------------------------------------------------------------------ folds ---

function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  local level = heading_level(line)
  if level then
    return ">" .. level
  end
  if line:match "^%s*$" then
    local last = vim.fn.line "$"
    for j = lnum + 1, last do
      local next_line = vim.fn.getline(j)
      if not next_line:match "^%s*$" then
        local next_level = heading_level(next_line)
        return next_level and tostring(next_level - 1) or "="
      end
    end
    return "0"
  end
  return "="
end

function M.foldtext()
  local start, finish = vim.v.foldstart, vim.v.foldend
  local line = vim.fn.getline(start)
  local hl = "OrgHeadingFold" .. math.min(heading_level(line) or 1, 8)
  local text = line .. "  … " .. (finish - start) .. " lines"
  local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local width = vim.api.nvim_win_get_width(0) - (info and info.textoff or 0)
  local pad = math.max(0, width - vim.fn.strdisplaywidth(text))
  return { { text .. string.rep(" ", pad), hl } }
end

-- ------------------------------------------------------------------ setup ---

function M.setup()
  set_highlights()
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("org_visuals", { clear = true }),
    callback = function()
      -- render-markdown redefines its groups on ColorScheme too; run after it.
      vim.schedule(set_highlights)
    end,
  })

  -- Full-width bars on heading lines, computed only for visible lines on redraw.
  vim.api.nvim_set_decoration_provider(ns, {
    on_win = function(_, _, buf)
      return vim.bo[buf].filetype == "org"
    end,
    on_line = function(_, _, buf, row)
      local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1]
      local level = line and heading_level(line)
      if level then
        vim.api.nvim_buf_set_extmark(buf, ns, row, 0, {
          line_hl_group = "OrgHeadingBg" .. math.min(level, 8),
          ephemeral = true,
        })
      end
    end,
  })
end

-- Window-local fold options; called from after/ftplugin/org.lua so it runs
-- after orgmode's own ftplugin (which sets treesitter folding).
function M.attach()
  vim.opt_local.foldexpr = "v:lua.require'configs.org.visuals'.foldexpr(v:lnum)"
  vim.opt_local.foldtext = "v:lua.require'configs.org.visuals'.foldtext()"
end

return M
