local constants = require('super-kanban.constants')
local hl = require('super-kanban.highlights')
local DatePicker = require('super-kanban.ui.date_picker')
local actions = require('super-kanban.actions')
local utils = require('super-kanban.utils')
local text = require('super-kanban.utils.text')
local date = require('super-kanban.utils.date')

---@type superkanban.Config
local config

---@class superkanban.Card.Opts
---@field data superkanban.TaskData
---@field index number
---@field list_index number
---@field ctx superkanban.Ctx

---@class superkanban.cardUI
---@field data superkanban.TaskData
---@field index number
---@field visible_index number
---@field win snacks.win
---@field list_index number
---@field ctx superkanban.Ctx
---@field type "card"
---@overload fun(opts:superkanban.Card.Opts): superkanban.cardUI
local M = setmetatable({}, {
  __call = function(t, ...)
    return t.new(...)
  end,
})
M.__index = M

---@param index number
---@param conf superkanban.Config
local function calculate_row_pos(index, conf)
  return (conf.card.height + 1) * (index - 1)
end

---@param opts superkanban.Card.Opts
---@return superkanban.cardUI
function M.new(opts)
  ---@diagnostic disable-next-line: param-type-mismatch
  local self = setmetatable({}, M)

  self.data = opts.data
  self.index = opts.index
  self.ctx = opts.ctx
  self.list_index = opts.list_index

  self.type = 'card'

  return self
end

function M.empty_data()
  return { title = '', check = ' ', tag = {}, due = {} }
end

---@param list superkanban.ListUI
---@return snacks.win
function M:setup_win(list)
  local conf = self.ctx.config

  self.win = Snacks.win({
    -- User cofig values
    width = conf.card.width,
    height = conf.card.height,
    border = conf.card.border,
    zindex = conf.card.zindex,
    wo = utils.merge({
      winbar = self:generate_winbar(),
      winhighlight = hl.card,
    }, conf.card.win_options),
    -- Non cofig values
    show = false,
    enter = false,
    relative = 'win',
    win = list.win.win,
    col = 0,
    row = calculate_row_pos(self.index, self.ctx.config),
    focusable = true,
    keys = { q = false },
    bo = { modifiable = true, filetype = 'superkanban_card' },
    on_win = function()
      vim.schedule(function()
        self:set_events()
        self:set_keymaps()
      end)
    end,
    text = function()
      return text.get_buf_lines_from_task(self.data)
    end,
  })

  return self.win
end

---@param list superkanban.ListUI
---@param opts? {win?:snacks.win,visible_index?:number}
function M:mount(list, opts)
  opts = opts or {}

  local win = opts.win
  if not win then
    win = self:setup_win(list)
  end

  if type(opts.visible_index) == 'number' then
    self.visible_index = opts.visible_index
    win:show()
  end

  return self
end

function M:focus()
  if self:closed() then
    self.win:show()
  end

  self.win:focus()
  self:update_hl(true, self.win.win)
  self:update_ctx_location()
end

function M:exit()
  self.win:close()
  self.visible_index = nil
end

function M:closed()
  return self.win.closed ~= false
end

function M:has_visual_index()
  return type(self.visible_index) == 'number' and self.visible_index > 0
end

function M:in_view()
  return self:has_visual_index() and not self:closed()
end

function M:generate_winbar()
  local f_str = '%%=%s%%#KanbanNone#%s'
  local checkmark, checkmark_hl = self.ctx.config.icons.card_checkmarks[' '], 'KanbanCheckMark'
  if self:is_complete() then
    checkmark, checkmark_hl = self.ctx.config.icons.card_checkmarks['x'], 'KanbanCheckMarkDone'
  end

  return f_str:format(utils.with_hl(checkmark, checkmark_hl), self:get_relative_date())
end

function M:update_winbar()
  local ft = vim.api.nvim_get_option_value('filetype', { buf = self.win.buf })

  if ft == 'superkanban_card' then
    vim.api.nvim_set_option_value('winbar', self:generate_winbar(), { win = self.win.win })
  end
end

function M:update_buffer_text()
  local lines = text.get_buf_lines_from_task(self.data)
  vim.api.nvim_buf_set_lines(self.win.buf, 0, -1, false, lines)
  return lines
end

function M:get_relative_date()
  if #self.data.due == 0 then
    return ''
  end
  local date_str = self.data.due[#self.data.due]
  if not date_str then
    return ''
  end
  local ok, result = pcall(date.get_relative_time, date.extract_date_obj_from_str(date_str))

  if ok then
    return ' ' .. result
  end

  return ''
end

---@param new_index? number
function M:update_visible_position(new_index)
  if type(new_index) == 'number' and new_index > 0 then
    self.win.opts.row = calculate_row_pos(new_index, self.ctx.config)

    if self:closed() then
      self.win:show()
    end

    self.visible_index = new_index
    self.win:update()
    self:update_winbar()
  else
    self.win:hide()
    self.visible_index = nil
  end
end

function M:extract_buffer_and_update_task_data()
  local lines = self.win:lines()

  local raw = table.concat(lines, ' ')
  local title, tags, due, date_obj = text.extract_task_data_from_str(raw)

  self.data.title = title
  self.data.tag = tags
  self.data.due = due
  self.data.date = date_obj
end

---@param is_active boolean
---@param win number
function M:update_hl(is_active, win)
  vim.api.nvim_set_option_value('winhighlight', is_active and hl.cardActive or hl.card, { win = win })
end

function M:is_complete()
  if not self.data.check or self.data.check == ' ' or self.data.check == '' then
    return false
  end

  return true
end

function M:update_ctx_location()
  self.ctx.location = { list = self.list_index, card = self.index }
end

function M:set_events()
  self.win:on({ 'BufEnter', 'WinEnter' }, function()
    self:update_hl(true, self.win.win)
    self:update_ctx_location()
  end, { buf = true })

  self.win:on({ 'BufLeave', 'WinLeave' }, function()
    self:update_hl(false, self.win.win)
  end, { buf = true })

  self.win:on({ 'TextChanged', 'TextChangedI', 'TextChangedP' }, function()
    self:extract_buffer_and_update_task_data()
    self:update_winbar()
  end, { buf = true })

  self.win:on({ 'TextChangedI' }, function()
    local found_pos = text.find_at_sign_before_cursor()
    if found_pos then
      vim.cmd.stopinsert()
      vim.schedule(function()
        self:pick_date(false, found_pos)
      end)
    end
  end, { buf = true })
end

function M:set_keymaps()
  local list = self.ctx.lists[self.list_index]
  actions._set_keymaps(self, list, self.ctx, self.win.buf)
end

---@param should_focus? boolean
function M:delete_card(should_focus)
  local list = self.ctx.lists[self.list_index]
  local target_index = self.index

  -- Remove card
  self:exit()
  table.remove(list.cards, target_index)
  list:update_winbar(#list.cards)

  list:fill_empty_space({ from = target_index - 1, to = target_index })

  -- focus on card or list
  if should_focus ~= false then
    local focus_target = list.cards[target_index] or list.cards[target_index - 1] or list
    focus_target:focus()
  end
end

---@param check? boolean
function M:toggle_complete(check)
  if check == true then
    self.data.check = constants.checkbox_checked
  elseif check == false then
    self.data.check = constants.checkbox_unchecked
  else
    self.data.check = self:is_complete() and constants.checkbox_unchecked or constants.checkbox_checked
  end

  self:update_winbar()
end

function M:move_to_archive()
  self.ctx.board:create_archive_list()

  self.data.check = constants.checkbox_checked
  table.insert(self.ctx.archive.tasks, self.data)

  self:delete_card()
end

---@param direction? number
function M:jump_vertical(direction)
  if direction == nil then
    direction = 1
  end
  local list = self.ctx.lists[self.list_index]
  if not list then
    return
  end
  if #list.cards == 0 then
    return
  end

  local target_card = list.cards[self.index + direction]
  if target_card and target_card:has_visual_index() then
    target_card:focus()
  elseif target_card and not target_card:has_visual_index() then
    list:scroll_list(direction, self.index)
    target_card:focus()
  end
end

---@param direction? number
function M:jump_horizontal(direction)
  if direction == nil then
    direction = 1
  end
  local target_list = self.ctx.lists[self.list_index + direction]
  if not target_list then
    return
  end

  if not target_list:has_visual_index() or target_list:closed() then
    self.ctx.board:scroll_board(direction, self.list_index)
  end

  if #target_list.cards == 0 then
    target_list:focus()
  end

  -- Focus same visual_index card
  if #target_list.cards >= self.visible_index then
    local target_card = target_list:find_a_visible_card(self.visible_index)
    if target_card then
      target_card:focus()
    end
  elseif target_list.cards[#target_list.cards] then
    target_list.cards[#target_list.cards]:focus()
  end
end

---@param direction? number
function M:move_vertical(direction)
  if direction == nil then
    direction = 1
  end
  local list = self.ctx.lists[self.list_index]
  if not list then
    return
  end

  if (#list.cards == 1) or (direction == 1 and self.index == #list.cards) or (direction == -1 and self.index == 1) then
    return
  end

  -- Update index
  local cur_index = self.index
  local target_index = self.index + direction
  local cur_card = list.cards[cur_index]
  local target_card = list.cards[target_index]

  if not target_card:in_view() then
    list:scroll_list(direction)
  end

  -- swap index
  local cur_v_index, target_v_index = target_card.visible_index, cur_card.visible_index
  cur_card.index, target_card.index = target_index, cur_index
  -- swap card in ctx
  list.cards[target_index], list.cards[cur_index] = cur_card, target_card

  cur_card:update_visible_position(cur_v_index)
  target_card:update_visible_position(target_v_index)
  cur_card:focus()
end

---@param direction? number
---@param placement? "first"|"last"
function M:move_horizontal(direction, placement)
  placement = placement or 'first'
  if direction == nil then
    direction = 1
  end
  local cur_list = self.ctx.lists[self.list_index]
  local target_list = self.ctx.lists[self.list_index + direction]
  if not target_list then
    return
  end

  if not target_list:has_visual_index() or target_list:closed() then
    self.ctx.board:scroll_board(direction, self.list_index)
  end

  -- Auto Update checkmark while moving to/from the list with **Complete** tag
  local updated_check_mark = nil
  if target_list.complete_task then
    updated_check_mark = constants.checkbox_checked
  elseif not target_list.complete_task and cur_list.complete_task then
    updated_check_mark = constants.checkbox_unchecked
  end

  -- Update card+list index and parent win
  local target_card_index = placement == 'last' and #target_list.cards + 1 or 1
  local new_card_data = vim.deepcopy(self.data)
  if updated_check_mark then
    new_card_data.check = updated_check_mark
  end
  local new_card = self
    .new({
      data = new_card_data,
      index = target_card_index,
      ctx = target_list.ctx,
      list_index = target_list.index,
    })
    :mount(target_list)
  table.insert(target_list.cards, target_card_index, new_card)

  if placement == 'last' then
    target_list:jump_to_last_card()
  else
    for index, card in pairs(target_list.cards) do
      if target_card_index ~= index then
        card.index = card.index + 1
      end
    end
    target_list:jump_to_first_card()
  end

  self:delete_card(false)
end

function M:pick_date(create_new_date, at_sign_pos)
  local data = create_new_date and {} or date.extract_date_obj_from_str(self.data.due[#self.data.due])
  local picker = DatePicker.new({ data = data }, self.ctx)
  picker:mount({
    on_select = function(selected_date)
      if not selected_date then
        self:focus()
        return
      end

      -- Update task date
      local f_date = date.format_to_date_str(selected_date)
      if #self.data.due > 0 then
        self.data.due[#self.data.due] = f_date
      else
        self.data.due[1] = f_date
      end
      self.data.title = text.remove_trailing_or_lonely_at_sign(self.data.title)
      self:update_buffer_text()

      self:focus()
      if at_sign_pos then
        vim.schedule(function()
          local use_bang = at_sign_pos.row >= 2 or utils.is_cursor_at_last_column(at_sign_pos.col)
          vim.cmd.startinsert({ bang = use_bang })
        end)
      end
    end,
    on_close = function()
      self:focus()
      if at_sign_pos then
        vim.schedule(function()
          local use_bang = utils.is_cursor_at_last_column(at_sign_pos.col)
          vim.cmd.startinsert({ bang = use_bang })
        end)
      end
    end,
  })
end

function M:remove_date()
  self.data.due = {}
  self:update_buffer_text()
  self:update_winbar()
end

---@param conf superkanban.Config
function M.setup(conf)
  config = conf
end

return M
