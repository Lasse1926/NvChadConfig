-- Org file shortcuts: one table drives both the keymaps and the labels in the
-- <leader>of fzf picker, so adding/removing a mapping here updates both.

local M = {}

M.dir = vim.fn.expand "~/orgfiles"

-- open(): optional custom opener; default is plain :edit
M.files = {
  { file = "work.org", key = "<leader>ow" },
  { file = "personal.org", key = "<leader>op" },
  { file = "refile.org", key = "<leader>oR", desc = "refile.org (inbox)" },
  { file = "school.org", key = "<leader>ob" },
  {
    file = "ticketState.org",
    key = "<leader>os",
    desc = "ticketState.org at today",
    open = function(path)
      vim.cmd.edit(vim.fn.fnameescape(path))
      local pattern = "^\\*\\+ " .. os.date "%Y-%m-%d"
      if vim.fn.search(pattern, "w") == 0 then
        vim.notify("No entry for today yet", vim.log.levels.INFO)
        return
      end
      -- orgmode applies its startup folding after the buffer loads; unfold after it
      vim.defer_fn(function()
        vim.cmd "normal! zv"
        pcall(vim.cmd, "normal! zO")
        vim.cmd "normal! zt"
      end, 50)
    end,
  },
}

local function open(name)
  local path = M.dir .. "/" .. name
  for _, f in ipairs(M.files) do
    if f.file == name and f.open then
      return f.open(path)
    end
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

function M.setup_keymaps()
  for _, f in ipairs(M.files) do
    vim.keymap.set("n", f.key, function()
      open(f.file)
    end, { desc = "Org | Open " .. (f.desc or f.file) })
  end
end

function M.pick()
  local keys = {}
  for _, f in ipairs(M.files) do
    keys[f.file] = f.key
  end

  -- only real .org files; skips *.org_archive
  local found = vim.fn.globpath(M.dir, "**/*.org", false, true)
  local names, width = {}, 0
  for _, p in ipairs(found) do
    local name = p:sub(#M.dir + 2):gsub("\\", "/")
    table.insert(names, name)
    width = math.max(width, #name)
  end
  -- mapped files first, then unmapped; each group alphabetical
  table.sort(names, function(a, b)
    if (keys[a] ~= nil) ~= (keys[b] ~= nil) then
      return keys[a] ~= nil
    end
    return a < b
  end)

  local entries, lookup = {}, {}
  for _, name in ipairs(names) do
    local label = keys[name] and string.format("%-" .. width .. "s   %s", name, keys[name]) or name
    table.insert(entries, label)
    lookup[label] = name
  end

  require("fzf-lua").fzf_exec(entries, {
    prompt = "Org Files> ",
    winopts = { title = " Org Files " },
    fzf_opts = { ["--multi"] = false, ["--no-sort"] = true },
    preview = function(items)
      local name = lookup[items[1]]
      if not name then
        return ""
      end
      local ok, lines = pcall(vim.fn.readfile, M.dir .. "/" .. name)
      return ok and table.concat(lines, "\n") or ""
    end,
    actions = {
      ["enter"] = function(selected)
        local name = selected and lookup[selected[1]]
        if name then
          open(name)
        end
      end,
    },
  })
end

return M
