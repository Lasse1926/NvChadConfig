-- fzf-lua replacement for NvChad's `:Telescope terms` extension
-- (nvim-data/lazy/ui/lua/telescope/_extensions/terms.lua), which dies with
-- telescope. The underlying data model is plugin-agnostic:
--   vim.g.nvchad_terms                 -- { [tostring(bufnr)] = <term opts> }
--   require("nvchad.term").display(o)  -- reopens a hidden term in its position
--
-- WARNING: do NOT require "nvchad.term" at module level. nvchad/term/init.lua
-- runs `g.nvchad_terms = {}` on first load, and that module is only loaded
-- lazily by NvChad's <A-h>/<A-v>/<A-i> mappings -- requiring it here could wipe
-- the registry before anything has populated it. Require it inside the action
-- only, exactly as the original extension does.

local M = {}

-- bufnr -> term opts (for nvchad-managed terms) or false (for plain :terminal)
local function collect()
  local nvterms = vim.g.nvchad_terms or {}
  local result = {}

  for buf, opts in pairs(nvterms) do
    result[tonumber(buf)] = opts
  end

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" and result[buf] == nil then
      result[buf] = false
    end
  end

  return result
end

function M.pick()
  local entries, lookup = {}, {}

  for buf, termopts in pairs(collect()) do
    if vim.api.nvim_buf_is_valid(buf) then
      local name = vim.api.nvim_buf_get_name(buf)
      local label = string.format("[%d] %s", buf, name ~= "" and name or "<terminal>")
      table.insert(entries, label)
      lookup[label] = { buf = buf, opts = termopts or nil }
    end
  end

  if #entries == 0 then
    vim.notify("no terminal buffers are opened/hidden!", vim.log.levels.INFO)
    return
  end

  table.sort(entries)

  require("fzf-lua").fzf_exec(entries, {
    prompt = "Pick Term> ",
    winopts = {
      title = "  Pick Term ",
      width = 0.5,
      height = 0.4,
      preview = { hidden = true },
    },
    actions = {
      ["enter"] = function(selected)
        local entry = selected and selected[1] and lookup[selected[1]]
        if not entry then
          return
        end

        -- Only open it if its window isn't already visible.
        if vim.fn.bufwinid(entry.buf) ~= -1 then
          return
        end

        if entry.opts then
          require("nvchad.term").display(entry.opts)
        else
          vim.api.nvim_set_current_buf(entry.buf)
        end
      end,
    },
  })
end

return M
