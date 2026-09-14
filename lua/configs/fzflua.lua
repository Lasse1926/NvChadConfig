-- fzf-lua options, consumed by the spec in lua/plugins/init.lua.
--
-- base46 compiles its "telescope" integration unconditionally (see
-- base46/lua/base46/init.lua:14-31) -- it does not care whether the telescope
-- PLUGIN is installed. So the Telescope* groups survive telescope's removal and
-- we reuse them, which keeps the picker on the active theme (currently eldritch)
-- and makes <leader>th theme switches propagate for free: hls values are group
-- NAMES, resolved live into winhl by fzf-lua's win.lua.
--
-- The dofile MUST run before require("fzf-lua").setup(): fzf-lua resolves the
-- "telescope" profile eagerly in setup(), and that profile guards every lookup
-- with is_hl_cleared(), silently dropping groups that don't exist yet. Normally
-- nvchad/configs/telescope.lua does this dofile; with telescope disabled nothing
-- else will. Same pattern as that file.
dofile(vim.g.base46_cache .. "telescope")

local options = {
  -- Base profile: telescope-like layout, keymaps and actions.
  "telescope",

  -- NvChad's telescope used sorting_strategy="ascending" with the prompt on
  -- top; --layout=reverse is the fzf equivalent. The profile alone puts the
  -- prompt at the bottom.
  fzf_opts = {
    ["--layout"] = "reverse",
  },

  -- Match NvChad's telescope geometry.
  winopts = {
    width = 0.87,
    height = 0.80,
    preview = {
      layout = "flex",
      flip_columns = 120,
      horizontal = "right:55%",
      vertical = "up:45%",
    },
  },

  hls = {
    normal = "TelescopeNormal",
    border = "TelescopeBorder",
    title = "TelescopePromptTitle",
    -- Not TelescopeResultsTitle: in the default "borderless" style base46 sets
    -- it fg == bg == darker_black, which would render the flags invisible.
    title_flags = "TelescopeSelection",
    preview_normal = "TelescopeNormal",
    preview_border = "TelescopeBorder",
    preview_title = "TelescopePreviewTitle",
    help_normal = "TelescopeNormal",
    help_border = "TelescopeBorder",
    cursor = "Cursor",
    cursorline = "TelescopeSelection",
    cursorlinenr = "TelescopeSelection",
    search = "IncSearch",
    scrollborder_e = "TelescopeBorder",
    scrollborder_f = "TelescopeMatching",

    -- Roles telescope has no counterpart for: plain syntax groups, which base46
    -- themes via the "defaults"/"syntax" caches already loaded at startup.
    header_bind = "Function",
    header_text = "Comment",
    path_colnr = "Number",
    path_linenr = "Number",
    buf_name = "Directory",
    buf_id = "Comment",
    buf_nr = "Number",
    buf_linenr = "LineNr",
    buf_flag_cur = "Special",
    buf_flag_alt = "Comment",
    tab_title = "Title",
    tab_marker = "Special",
    dir_icon = "Directory",
    dir_part = "Comment",
    file_part = "Normal",
    live_prompt = "Special",
  },

  -- Colors handed to the fzf binary itself. The telescope profile points three
  -- of these at groups base46 does NOT define (TelescopeMultiSelection,
  -- TelescopeSelectionCaret, TelescopeTitle); fzf-lua would silently drop those
  -- flags, so repoint them at groups that do exist rather than inventing new ones.
  fzf_colors = {
    ["fg"] = { "fg", "TelescopeNormal" },
    ["bg"] = { "bg", "TelescopeNormal" },
    ["hl"] = { "fg", "TelescopeMatching" },
    ["fg+"] = { "fg", "TelescopeSelection" },
    ["bg+"] = { "bg", "TelescopeSelection" },
    ["hl+"] = { "fg", "TelescopeMatching" },
    ["border"] = { "fg", "TelescopeBorder" },
    ["gutter"] = { "bg", "TelescopeNormal" },
    ["query"] = { "fg", "TelescopePromptNormal" },
    ["prompt"] = { "fg", "TelescopePromptPrefix" },
    ["pointer"] = { "fg", "TelescopePromptPrefix" },
    ["marker"] = { "fg", "TelescopePromptPrefix" },
    ["header"] = { "fg", "TelescopePreviewTitle" },
    ["info"] = { "fg", "Comment" },
  },

  -- telescope's find_files showed a plain title, not a shortened cwd.
  files = { cwd_prompt = false },
}

return options
