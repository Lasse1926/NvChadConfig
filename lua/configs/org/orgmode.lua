-- nvim-orgmode setup plus local tweaks.
-- Capture templates: lua/configs/org/capture.lua
-- File shortcuts / <leader>of picker: lua/configs/orgfiles.lua

local M = {}

-- Refile to a bare file ("personal.org") lands under the heading in that
-- file that has the property `:REFILE_DEFAULT: t`, instead of top level.
-- Typing "personal.org/Some Heading" still works as before.
local function setup_refile_default()
  local Capture = require "orgmode.capture"
  local get_destination = Capture.get_destination
  function Capture:get_destination()
    return get_destination(self):next(function(dest)
      if dest and dest.file and not dest.headline then
        for _, headline in ipairs(dest.file:get_headlines()) do
          if headline:get_property("REFILE_DEFAULT", false) then
            dest.headline = headline
            break
          end
        end
      end
      return dest
    end)
  end
end

-- Buffer-local keymaps for org files.
local function setup_buffer_keymaps()
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "org",
    callback = function(ev)
      -- <leader>oxp: checklist picker for the heading's properties
      -- (lua/configs/org/property_picker.lua).
      vim.keymap.set("n", "<leader>oxp", function()
        require("configs.org.property_picker").open()
      end, { buffer = ev.buf, desc = "org edit properties" })

      -- Visual > / <: demote / promote every heading in the selection by one level
      -- (uses orgmode's own >> / << so body indentation is adjusted too).
      local function shift_selected(action)
        return function()
          local s, e = vim.fn.line "v", vim.fn.line "."
          if s > e then
            s, e = e, s
          end
          vim.cmd "normal! \27" -- leave visual mode
          for lnum = s, e do
            if vim.fn.getline(lnum):match "^%*+%s" then
              vim.api.nvim_win_set_cursor(0, { lnum, 0 })
              require("orgmode").action(action)
            end
          end
          vim.api.nvim_win_set_cursor(0, { s, 0 })
          vim.cmd "normal! gv" -- keep selection so you can press > again
        end
      end
      vim.keymap.set("x", ">", shift_selected "org_mappings.do_demote", { buffer = ev.buf, desc = "org demote selected headings" })
      vim.keymap.set("x", "<", shift_selected "org_mappings.do_promote", { buffer = ev.buf, desc = "org promote selected headings" })
    end,
  })
end

-- Soft limit: warn on save when a top-level (*) heading has more than 1 NEXT
-- in its subtree (a NEXT on the top-level heading itself counts too).
local function setup_next_warning()
  vim.api.nvim_create_autocmd("BufWritePost", {
    pattern = "*.org",
    callback = function(ev)
      local order, current = {}, nil
      for i, l in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
        if l:match "^%*%s" then
          local title = l:gsub("^%*%s+", ""):gsub("^%u+%s+", ""):gsub("%s+:[%w_@#%%:]+:%s*$", "")
          current = { title = title, lines = {} }
          table.insert(order, current)
        end
        if current and (l:match "^%*+%s+NEXT%s" or l:match "^%*+%s+NEXT$") then
          table.insert(current.lines, i)
        end
      end
      local msgs = {}
      for _, g in ipairs(order) do
        if #g.lines > 1 then
          table.insert(msgs, string.format("  %s: %d NEXT (lines %s)", g.title, #g.lines, table.concat(g.lines, ", ")))
        end
      end
      if #msgs > 0 then
        vim.notify(
          vim.fn.fnamemodify(ev.file, ":t") .. " - keep 1 NEXT per heading:\n" .. table.concat(msgs, "\n"),
          vim.log.levels.WARN
        )
      end
    end,
  })
end

-- "Next actions" agenda view (<leader>oa n): append the top-level heading
-- each NEXT belongs to, e.g. "work: NEXT Email Tom  ‹Project X›".
local function setup_next_agenda_parent()
  local TodosType = require "orgmode.agenda.types.todo"
  local build_line = TodosType._build_line
  function TodosType:_build_line(headline, metadata)
    local line = build_line(self, headline, metadata)
    if not (self.id and self.id:match "^n_") then
      return line
    end
    local ok, top = pcall(function()
      local h = headline
      while h:get_level() > 1 do
        h = h:get_parent_headline()
      end
      return h ~= headline and (h:get_title()) or nil
    end)
    if ok and top then
      -- Tags are right-aligned virtual text but still advance the column
      -- counter, so pull them off, add our token, then re-add them.
      local virt = {}
      for i = #line.tokens, 1, -1 do
        local t = line.tokens[i]
        if t.virt_text_pos then
          table.insert(virt, 1, table.remove(line.tokens, i))
          line.col_counter = line.col_counter - #t.content - (#line.tokens > 0 and #line.separator or 0)
        end
      end
      line:add_token(require("orgmode.agenda.view.token"):new { content = "‹" .. top .. "›", hl_group = "Comment" })
      for _, t in ipairs(virt) do
        line:add_token(t)
      end
    end
    return line
  end
end

function M.setup()
  require("orgmode").setup {
    org_agenda_files = "~/orgfiles/**/*",
    org_default_notes_file = "~/orgfiles/refile.org",
    org_todo_keywords = { "TODO", "NEXT", "|", "DONE", "CANCELLED" },
    org_capture_templates = require "configs.org.capture",
    org_agenda_custom_commands = {
      n = {
        description = "Next actions",
        types = {
          { type = "tags_todo", match = "/NEXT", org_agenda_overriding_header = "Next actions" },
        },
      },
    },
  }

  setup_refile_default()
  setup_buffer_keymaps()
  setup_next_warning()
  setup_next_agenda_parent()
  require("configs.org.todo_deps").setup()

  vim.lsp.enable "org"
end

return M
