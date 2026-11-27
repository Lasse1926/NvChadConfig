-- Emacs-style TODO dependencies (org-enforce-todo-dependencies) for nvim-orgmode.
--
-- Only blocks moving from a not-done keyword (TODO/NEXT) to a done one
-- (DONE/CANCELLED). TODO <-> NEXT is always allowed.
--   - A heading can't be done while any descendant is still TODO/NEXT.
--   - :NOBLOCKING: t on the heading turns that check off for it.
--   - :OPTIONAL: t on a descendant makes it (and its subtree) ignored.
--   - :ORDERED: t on a parent: its children must be done top to bottom.
--     This also applies through ancestors, like in Emacs.
--
-- nvim-orgmode has no pre-change hook, so this replaces the private
-- OrgMappings:_change_todo_state. If orgmode's internals change, a warning
-- is shown at startup and blocking is turned off (orgmode keeps working).

local M = {}

local function warn(msg)
  vim.schedule(function()
    vim.notify("org deps: " .. msg, vim.log.levels.WARN)
  end)
end

---@return boolean
local function prop_true(headline, name)
  local value = headline:get_property(name, false)
  return value ~= nil and value ~= "" and value:lower() ~= "nil"
end

local function same(a, b)
  return a:get_range().start_line == b:get_range().start_line
end

-- First open (TODO/NEXT) descendant that isn't OPTIONAL, or nil.
local function open_descendant(headline)
  for _, child in ipairs(headline:get_child_headlines()) do
    if not prop_true(child, "OPTIONAL") then
      if child:is_todo() then
        return child
      end
      local found = open_descendant(child)
      if found then
        return found
      end
    end
  end
end

-- First open earlier sibling under an ORDERED parent, walking up through ancestors.
local function open_ordered_sibling(headline)
  local current = headline
  while current:get_level() > 1 do
    local parent = current:get_parent_headline()
    if not parent then
      return nil
    end
    if prop_true(parent, "ORDERED") then
      for _, sibling in ipairs(parent:get_child_headlines()) do
        if same(sibling, current) then
          break
        end
        if sibling:is_todo() and not prop_true(sibling, "OPTIONAL") then
          return sibling
        end
      end
    end
    current = parent
  end
end

-- Heading that blocks `headline` from becoming done, or nil.
local function find_blocker(headline)
  if not prop_true(headline, "NOBLOCKING") then
    local child = open_descendant(headline)
    if child then
      return child
    end
  end
  return open_ordered_sibling(headline)
end

function M.setup()
  local ok_m, OrgMappings = pcall(require, "orgmode.org.mappings")
  local ok_t, TodoState = pcall(require, "orgmode.objects.todo_state")
  local ok_u, utils = pcall(require, "orgmode.utils")

  local missing = {}
  if not ok_m or type(OrgMappings._change_todo_state) ~= "function" then
    table.insert(missing, "OrgMappings._change_todo_state")
  end
  if not ok_t then
    table.insert(missing, "orgmode.objects.todo_state")
  else
    for _, fn in ipairs { "new", "has_fast_access", "open_fast_access", "get_next", "get_prev" } do
      if type(TodoState[fn]) ~= "function" then
        table.insert(missing, "TodoState." .. fn)
      end
    end
  end
  if not ok_u or type(utils.echo_info) ~= "function" then
    table.insert(missing, "utils.echo_info")
  end
  if #missing > 0 then
    warn("orgmode internals changed, TODO dependency blocking is OFF. Missing: " .. table.concat(missing, ", "))
    return
  end

  -- Copy of orgmode's OrgMappings:_change_todo_state (lua/orgmode/org/mappings.lua)
  -- with the dependency check inserted before set_todo. Returning false makes the
  -- caller abort: no event, no log note, no repeater, no buffer edit.
  function OrgMappings:_change_todo_state(direction, use_fast_access)
    local headline = self.files:get_closest_headline()
    local current_keyword = headline:get_todo() or ""

    local todos = headline.file:get_todo_keywords()

    local todo_state = TodoState:new { current_state = current_keyword, todos = todos }
    local next_state = nil

    if use_fast_access and todo_state:has_fast_access() then
      next_state = todo_state:open_fast_access()
    else
      if direction == "next" then
        next_state = todo_state:get_next()
      elseif direction == "prev" then
        next_state = todo_state:get_prev()
      end
    end

    if not next_state then
      return false
    end

    if next_state.value == current_keyword then
      if current_keyword ~= "" then
        utils.echo_info("TODO state was already ", { {
          next_state.value,
          next_state.hl,
        } })
      end
      return false
    end

    -- Emacs: only not-done -> done is checked.
    if headline:is_todo() and next_state.type == "DONE" then
      local blocker = find_blocker(headline)
      if blocker then
        vim.notify(
          ("%s blocked by: %s %s"):format(next_state.value, blocker:get_todo() or "", (blocker:get_title())),
          vim.log.levels.WARN
        )
        return false
      end
    end

    headline:set_todo(next_state.value)
    return true
  end
end

return M
