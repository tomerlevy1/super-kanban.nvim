local minidoc = require('mini.doc')
vim.cmd.wa()

local function visual_text_width(text)
  -- Ignore concealed characters (usually "invisible" in 'help' filetype)
  local _, n_concealed_chars = text:gsub('([*|`])', '%1')
  return vim.fn.strdisplaywidth(text) - n_concealed_chars
end

if _G.MiniDoc == nil then
  minidoc.setup()
end

local hooks = vim.deepcopy(MiniDoc.default_hooks)

hooks.write_pre = function(lines)
  -- Remove first two lines with `======` and `------` delimiters to comply
  -- with `:h local-additions` template
  table.remove(lines, 1)
  table.remove(lines, 1)

  -- Insert last modified date into the first line
  local formatted_date = 'Last change: ' .. os.date('%Y %B %d')
  local left_width = visual_text_width(lines[1])
  local n_left = 78 - (left_width + #formatted_date) - 2
  lines[1] = lines[1] .. (' '):rep(n_left) .. formatted_date

  return lines
end

MiniDoc.generate({
  'lua/super-kanban.lua',
  'lua/super-kanban/highlights.lua',
}, 'doc/super-kanban.txt', { hooks = hooks })

-- R('scripts.doc')
