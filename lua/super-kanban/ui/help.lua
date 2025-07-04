local utils = require('super-kanban.utils')
local text_utils = require('super-kanban.utils.text')
local hl = require('super-kanban.highlights')

---@type superkanban.Config
local config

local ns_help = vim.api.nvim_create_namespace('super-kanban-help')

local M = {}

---@param focus_item superkanban.cardUI|superkanban.ListUI|nil
function M.show(focus_item)
  if not focus_item then
    return
  end
  local note_conf = config.note_popup

  local win

  win = Snacks.win({
    -- User config values
    width = note_conf.width,
    height = note_conf.height,
    border = note_conf.border,
    zindex = note_conf.zindex,
    wo = utils.merge({
      winhighlight = hl.note_popup,
      cursorline = true,
    }, note_conf.win_options),
    -- Non config values
    show = false,
    backdrop = false,
    on_win = function()
      vim.schedule(function()
        M.render_lines(win, focus_item)
      end)
    end,
  })

  win:show()
end

---@param win snacks.win
---@param focus_item superkanban.cardUI|superkanban.ListUI
function M.render_lines(win, focus_item)
  local keymaps = vim.api.nvim_buf_get_keymap(focus_item.win.buf, 'n')

  local buf = win.buf
  if not buf then
    return
  end

  local left_width = 10
  local width = vim.api.nvim_win_get_width(win.win)
  local heading = { ' SuperKanban Mappings', "press 'q' to exit " }
  local devider_line = { { ('─'):rep(width), 'SuperKanbanNoteBorder' } }

  local lines = {}

  local function generate_buf_line(keymap_list)
    for _, value in pairs(keymap_list) do
      local lhs = value.lhs:gsub(' ', '<space>')
      local desc = type(value.desc) == 'string' and value.desc or '<function>'

      local ignore_keymap = (value == false or string.find(desc, '^which%-key'))

      if not ignore_keymap then
        table.insert(lines, {
          { '  ' },
          { lhs, 'Constant' },
          { (' '):rep(left_width - #lhs) },
          { '| ' },
          { desc },
        })
      end
    end
  end

  -- Add card or list keymaps
  vim.list_extend(lines, {
    { { heading[1], 'Function' }, { (' '):rep(width - #heading[1] - #heading[2]) }, { heading[2], 'Function' } },
    devider_line,
  })
  generate_buf_line(keymaps)

  -- Add DatePicker keymaps
  vim.list_extend(lines, { devider_line, { { ' DatePiccker Mappings', 'Function' } }, devider_line })
  generate_buf_line(require('super-kanban.ui.date_picker')._keys)

  -- Add note_popup keymaps
  vim.list_extend(lines, { devider_line, { { ' Note Popup Mappings', 'Function' } }, devider_line })
  generate_buf_line(require('super-kanban.ui.note_popup')._keys)

  text_utils.render_lines(buf, ns_help, lines)
  vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
end

---@param conf superkanban.Config
function M.setup(conf)
  config = conf
end

return M
