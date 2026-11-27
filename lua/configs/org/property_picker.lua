-- Checklist property picker for the heading under the cursor (<leader>oxp).
--
--   [x] checked  -> property is kept / set
--   [ ] unchecked -> property is removed (or not added)
--   [=] locked   -> written by orgmode itself (ID, ARCHIVE_*, ...), never touched
--
-- Keys: space/x toggle · e edit value · a add new · <CR> apply · q/<Esc> cancel
-- Apply makes the drawer exactly the checked list. Uses only orgmode's public API.

local M = {}

local DEFAULTS = { "ORDERED", "NOBLOCKING", "OPTIONAL", "REFILE_DEFAULT", "CATEGORY", "EFFORT" }

local BOOLEAN = { ORDERED = true, NOBLOCKING = true, OPTIONAL = true, REFILE_DEFAULT = true }

local LOCKED = {
  ID = true,
  LAST_REPEAT = true,
  ARCHIVE_TIME = true,
  ARCHIVE_FILE = true,
  ARCHIVE_OLPATH = true,
  ARCHIVE_CATEGORY = true,
  ARCHIVE_TODO = true,
}

local FOOTER = { "", "space toggle · e edit value · a add", "<CR> apply · q cancel" }

local ns = vim.api.nvim_create_namespace "org_property_picker"

-- Property names used anywhere in the org files (uppercased).
local function names_in_files()
  local ok, files = pcall(function()
    return require("orgmode.api").load()
  end)
  local names = {}
  if not ok or type(files) ~= "table" then
    return names
  end
  for _, file in ipairs(files) do
    for _, headline in ipairs(file.headlines or {}) do
      for name in pairs(headline.properties or {}) do
        names[name:upper()] = true
      end
    end
  end
  return names
end

local function build_items(headline)
  local items, seen = {}, {}
  local function add(item)
    if not seen[item.name] then
      seen[item.name] = true
      table.insert(items, item)
    end
  end

  local existing = {}
  for name, value in pairs(headline.properties or {}) do
    table.insert(existing, { name = name:upper(), value = value })
  end
  table.sort(existing, function(a, b)
    return a.name < b.name
  end)
  for _, p in ipairs(existing) do
    add { name = p.name, value = p.value, checked = true, existing = true, locked = LOCKED[p.name] or false }
  end

  for _, name in ipairs(DEFAULTS) do
    add { name = name, checked = false, existing = false, locked = false }
  end

  local others = {}
  for name in pairs(names_in_files()) do
    if not seen[name] and not LOCKED[name] then
      table.insert(others, name)
    end
  end
  table.sort(others)
  for _, name in ipairs(others) do
    add { name = name, checked = false, existing = false, locked = false }
  end

  for _, item in ipairs(items) do
    item.orig_checked, item.orig_value = item.checked, item.value
  end
  return items
end

-- Pure diff: what apply would do. Exposed for testing.
function M._changes(items)
  local set, remove = {}, {}
  for _, item in ipairs(items) do
    if not item.locked then
      if item.existing and not item.checked then
        table.insert(remove, item.name)
      elseif item.checked and (not item.existing or item.value ~= item.orig_value) then
        table.insert(set, { name = item.name, value = item.value, new = not item.existing })
      end
    end
  end
  return set, remove
end

function M.open()
  if vim.bo.filetype ~= "org" then
    vim.notify("org props: not an org buffer", vim.log.levels.WARN)
    return
  end
  local ok, headline = pcall(function()
    return require("orgmode.api").current():get_closest_headline()
  end)
  if not ok or not headline then
    vim.notify("org props: no heading under the cursor", vim.log.levels.WARN)
    return
  end

  local origin_win = vim.api.nvim_get_current_win()
  local items = build_items(headline)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "org_property_picker"

  local function render()
    local width_name = 0
    for _, item in ipairs(items) do
      width_name = math.max(width_name, #item.name)
    end
    local lines = {}
    for _, item in ipairs(items) do
      local box = item.locked and "[=]" or (item.checked and "[x]" or "[ ]")
      local line = box .. " " .. item.name
      if item.value and item.value ~= "" then
        line = ("%s %-" .. width_name .. "s = %s"):format(box, item.name, item.value)
      end
      table.insert(lines, line)
    end
    vim.list_extend(lines, FOOTER)
    vim.bo[buf].modifiable = true
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].modifiable = false
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for i, item in ipairs(items) do
      if item.locked or not item.checked then
        vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = #lines[i], hl_group = "Comment" })
      end
    end
    for i = #items + 1, #lines do
      vim.api.nvim_buf_set_extmark(buf, ns, i - 1, 0, { end_col = #lines[i], hl_group = "Comment" })
    end
    return lines
  end

  local lines = render()
  local width = 40
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l) + 4)
  end
  local height = math.min(#lines, vim.o.lines - 6)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    title = " Properties: " .. (headline.title or "") .. " ",
    title_pos = "center",
    style = "minimal",
  })
  vim.wo[win].cursorline = true

  local function current_item()
    local row = vim.api.nvim_win_get_cursor(win)[1]
    return items[row], row
  end

  local function close()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_win_is_valid(origin_win) then
      vim.api.nvim_set_current_win(origin_win)
    end
  end

  local function locked_msg(item)
    vim.notify(("org props: %s is managed by orgmode"):format(item.name), vim.log.levels.INFO)
  end

  local function ask_value(item, on_done)
    vim.ui.input({ prompt = item.name .. " value: ", default = item.value or "" }, function(value)
      if value ~= nil and vim.trim(value) ~= "" then
        item.value = vim.trim(value)
        item.checked = true
      end
      if vim.api.nvim_buf_is_valid(buf) then
        render()
      end
      if on_done then
        on_done()
      end
    end)
  end

  local function toggle()
    local item = current_item()
    if not item then
      return
    end
    if item.locked then
      return locked_msg(item)
    end
    if item.checked then
      item.checked = false
    elseif item.value and item.value ~= "" then
      item.checked = true
    elseif BOOLEAN[item.name] then
      item.value, item.checked = "t", true
    else
      return ask_value(item)
    end
    render()
  end

  local function edit()
    local item = current_item()
    if not item then
      return
    end
    if item.locked then
      return locked_msg(item)
    end
    ask_value(item)
  end

  local function add_new()
    vim.ui.input({ prompt = "New property name: " }, function(name)
      if not name then
        return
      end
      name = vim.trim(name):upper()
      if not name:match "^[%w_%-]+$" then
        if name ~= "" then
          vim.notify("org props: invalid name " .. name, vim.log.levels.WARN)
        end
        return
      end
      for i, item in ipairs(items) do
        if item.name == name then
          vim.api.nvim_win_set_cursor(win, { i, 0 })
          return toggle()
        end
      end
      -- insert after the last existing property
      local pos = 1
      for i, item in ipairs(items) do
        if item.existing then
          pos = i + 1
        end
      end
      local item = { name = name, checked = false, existing = false, locked = LOCKED[name] or false }
      table.insert(items, pos, item)
      render()
      vim.api.nvim_win_set_cursor(win, { pos, 0 })
      if BOOLEAN[name] then
        item.value, item.checked = "t", true
        render()
      else
        ask_value(item)
      end
    end)
  end

  local function apply()
    local set, remove = M._changes(items)
    close()
    if #set == 0 and #remove == 0 then
      return
    end
    local done, err = pcall(function()
      for _, name in ipairs(remove) do
        headline:set_property(name, nil):wait()
      end
      for _, p in ipairs(set) do
        headline:set_property(p.name, p.value):wait()
      end
    end)
    if not done then
      vim.notify("org props: failed: " .. tostring(err), vim.log.levels.ERROR)
      return
    end
    local added, changed = 0, 0
    for _, p in ipairs(set) do
      if p.new then
        added = added + 1
      else
        changed = changed + 1
      end
    end
    vim.notify(("org props: +%d ~%d -%d"):format(added, changed, #remove))
  end

  local opts = { buffer = buf, nowait = true, silent = true }
  vim.keymap.set("n", "<Space>", toggle, opts)
  vim.keymap.set("n", "x", toggle, opts)
  vim.keymap.set("n", "e", edit, opts)
  vim.keymap.set("n", "a", add_new, opts)
  vim.keymap.set("n", "<CR>", apply, opts)
  vim.keymap.set("n", "q", close, opts)
  vim.keymap.set("n", "<Esc>", close, opts)

  -- keep the cursor on item lines
  vim.api.nvim_create_autocmd("CursorMoved", {
    buffer = buf,
    callback = function()
      local row = vim.api.nvim_win_get_cursor(win)[1]
      if row > #items and #items > 0 then
        vim.api.nvim_win_set_cursor(win, { #items, 0 })
      end
    end,
  })
  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    callback = function()
      -- vim.ui.input may open its own float; only close when focus goes elsewhere for good
      vim.schedule(function()
        local cur = vim.api.nvim_get_current_win()
        if vim.api.nvim_win_is_valid(win) and cur ~= win and vim.api.nvim_win_get_config(cur).relative == "" then
          close()
        end
      end)
    end,
  })

  return { buf = buf, win = win, items = items }
end

return M
