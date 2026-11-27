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
local AGENDA_CURSOR_MIX = 0.20 -- agenda cursor line (level-1 color)

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

-- Folded-bar bg per level, and cache of combined "<source fg> on folded bar"
-- groups (built lazily in foldtext, since orgmode defines its keyword/tag
-- groups after we run). Both reset whenever highlights are recomputed.
local fold_bgs = {}
local fold_part_groups = {}

local function set_highlights()
  local p = palette()
  local normal_bg = vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg
  local base = normal_bg and string.format("#%06x", normal_bg) or p.black
  for n = 1, 8 do
    local color = p[LEVEL_COLORS[math.min(n, #LEVEL_COLORS)]]
    fold_bgs[n] = mix(color, base, FOLD_MIX)
    vim.api.nvim_set_hl(0, "@org.headline.level" .. n, { fg = color, bold = true })
    vim.api.nvim_set_hl(0, "OrgHeadingBg" .. n, { bg = mix(color, base, BAR_MIX) })
    vim.api.nvim_set_hl(0, "OrgHeadingFold" .. n, { fg = color, bg = fold_bgs[n], bold = true })
  end
  fold_part_groups = {}

  -- Agenda cursor line: stronger than the theme's CursorLine so the row is
  -- easy to follow from title to right-aligned tags.
  vim.api.nvim_set_hl(0, "OrgAgendaCursorLine", { bg = mix(p[LEVEL_COLORS[1]], base, AGENDA_CURSOR_MIX) })
end

-- Highlight group with `source`'s foreground on level `level`'s folded bar.
local function fold_part(source, level)
  local name = "OrgFold_" .. source:gsub("[^%w]", "_") .. "_" .. level
  if not fold_part_groups[name] then
    local src = vim.api.nvim_get_hl(0, { name = source, link = false })
    vim.api.nvim_set_hl(0, name, { fg = src.fg, bg = fold_bgs[level], bold = src.bold })
    fold_part_groups[name] = true
  end
  return name
end

-- TODO keywords from the orgmode config: { TODO = "todo", DONE = "done", ... }
local function keyword_types()
  local ok, config = pcall(require, "orgmode.config")
  local list = ok and config.org_todo_keywords or { "TODO", "|", "DONE" }
  local types, kind = {}, "todo"
  for _, kw in ipairs(list) do
    if kw == "|" then
      kind = "done"
    else
      types[(kw:gsub("%(.*%)$", ""))] = kind -- strip fast-access key, e.g. "TODO(t)"
    end
  end
  return types
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
  local level = math.min(heading_level(line) or 1, 8)
  local hl = "OrgHeadingFold" .. level
  local chunks = {}
  local function add(text, group)
    if text ~= "" then
      table.insert(chunks, { text, group })
    end
  end

  -- "** TODO Title   :tag1:tag2:" -> stars | keyword | title | tags
  local stars, rest = line:match "^(%*+%s*)(.*)$"
  if not stars then
    stars, rest = "", line
  end
  add(stars, hl)
  local kw, after = rest:match "^(%u+)(%s.*)$"
  if not kw then
    kw, after = rest:match "^(%u+)$", ""
  end
  local kind = kw and keyword_types()[kw]
  if kind then
    add(kw, fold_part("@org.keyword." .. kind, level))
    rest = after
  end
  local title, gap, tags = rest:match "^(.-)(%s+)(:[%w_@#%%:]+:)%s*$"
  if tags then
    add(title .. gap, hl)
    add(tags, fold_part("@org.tag", level))
  else
    add(rest, hl)
  end
  local hidden = finish - start
  add("  … " .. hidden .. (hidden == 1 and " line" or " lines"), hl)

  local used = 0
  for _, c in ipairs(chunks) do
    used = used + vim.fn.strdisplaywidth(c[1])
  end
  local info = vim.fn.getwininfo(vim.api.nvim_get_current_win())[1]
  local width = vim.api.nvim_win_get_width(0) - (info and info.textoff or 0)
  add(string.rep(" ", math.max(0, width - used)), hl)
  return chunks
end

-- ------------------------------------------------------------------ setup ---

function M.setup()
  set_highlights()
  local group = vim.api.nvim_create_augroup("org_visuals", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = function()
      -- render-markdown redefines its groups on ColorScheme too; run after it.
      vim.schedule(set_highlights)
    end,
  })

  -- Agenda: highlight the cursor row across the full width.
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = "orgagenda",
    callback = function()
      vim.wo.cursorline = true
      -- NvChad sets cursorlineopt=number globally (only the number is lit).
      vim.wo.cursorlineopt = "both"
      vim.wo.winhighlight = "CursorLine:OrgAgendaCursorLine"
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
