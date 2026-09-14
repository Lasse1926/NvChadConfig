-- Diff the current buffer against a file picked with fzf-lua, side by side.
--
-- Neither diffview.nvim nor gitsigns can do this: both are git-only, diffing a
-- file against a revision rather than against another file. This is plain
-- :diffthis, with fzf-lua supplying the file picker.

local M = {}

function M.pick_and_diff()
  -- Covers nvim-tree (nofile), terminals/:PyRepl, help and quickfix in one
  -- check. Done before opening the picker so a pick isn't wasted.
  if vim.bo.buftype ~= "" then
    vim.notify("Diff: not available for this buffer type", vim.log.levels.WARN)
    return
  end

  local fzf = require "fzf-lua"
  local origin_win = vim.api.nvim_get_current_win()

  fzf.files {
    prompt = "Diff against> ",
    fzf_opts = { ["--multi"] = false },
    actions = {
      -- "enter", not "default" -- the latter is only a back-compat alias.
      -- Call-site actions merge with the provider defaults, so ctrl-v/s/t and
      -- alt-q keep working inside this picker.
      ["enter"] = function(selected, opts)
        if not selected or not selected[1] then
          return
        end

        -- Strips devicons, ANSI colouring and any :line:col suffix.
        local entry = fzf.path.entry_to_file(selected[1], opts)

        -- Prefer the existing buffer when the file is already open, so we don't
        -- create a duplicate. bufadd takes the name literally, which keeps us
        -- clear of Ex-command quoting entirely.
        local target = entry.bufnr
        if not target then
          local file = entry.path
          if not file or #file == 0 then
            return
          end
          if not fzf.path.is_absolute(file) then
            file = fzf.path.join { opts.cwd or opts._cwd or vim.uv.cwd(), file }
          end
          -- Deliberately not path.normalize()'d: it rewrites \ to / on Windows,
          -- which would reduce the chance of matching an already-open buffer.
          target = vim.fn.bufadd(file)
        end
        if target == 0 then
          return
        end

        -- fzf's window is already closed by now, but be explicit about where
        -- the split is going.
        if vim.api.nvim_win_is_valid(origin_win) then
          vim.api.nvim_set_current_win(origin_win)
        end

        -- Without this you get two panes and no highlights, which reads as a
        -- broken feature rather than an empty diff.
        if target == vim.api.nvim_get_current_buf() then
          vim.notify("Diff: that's the current file", vim.log.levels.INFO)
          return
        end

        -- We build the split by hand rather than using :vert diffsplit, so
        -- diffthis has to be called in both windows.
        vim.cmd "diffthis"
        vim.cmd "vsplit" -- splitright is on, so the picked file lands right
        vim.bo[target].buflisted = true
        vim.api.nvim_win_set_buf(0, target)
        vim.cmd "diffthis"
      end,
    },
  }
end

return M
