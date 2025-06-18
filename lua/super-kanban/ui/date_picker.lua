local utils = require('super-kanban.utils')
local text = require('super-kanban.utils.text')
local hl = require('super-kanban.highlights')

---@type superkanban.Config
local config

---@class superkanban.DatePicker.NewOpts
---@field data? superkanban.DatePickerDataOpts
---@field row? number
---@field col? number
---@field relative? string

---@class superkanban.DatePicker.MountOpts
---@field on_select fun(date: superkanban.DatePickerData)
---@field on_close? fun()

---@class superkanban.DatePickerUI
---@field data superkanban.DatePickerData
---@field current_year integer
---@field current_month integer
---@field current_day integer
---@field win snacks.win
---@field border_win snacks.win
---@field win_opts {row:number,col:number,relative:string}
---@field ctx superkanban.Ctx
---@field type "date_picker"
---@overload fun(opts?:superkanban.DatePicker.NewOpts,ctx:superkanban.Ctx): superkanban.cardUI
local M = setmetatable({}, {
  __call = function(t, ...)
    return t.new(...)
  end,
})
M.__index = M

local ns_date_picker = vim.api.nvim_create_namespace('super-kanban-date-picker')
local ns_date_under_cursor = vim.api.nvim_create_namespace('super-kanban-date-picker-date-under-cursor')
local ns_date_today = vim.api.nvim_create_namespace('super-kanban-date-picker-today')

---@param year number
---@param month number
local function get_days_in_month(year, month)
  -- If month is December, next month is January of next year
  if month == 12 then
    year = year + 1
    month = 1
  else
    month = month + 1
  end

  -- Go to the first day of the next month, then subtract one day
  local last_day_of_month = os.time({ year = year, month = month, day = 1 }) - 86400
  return tonumber(os.date('%d', last_day_of_month))
end

local weekday_map = {
  Sunday = 0,
  Monday = 1,
  Tuesday = 2,
  Wednesday = 3,
  Thursday = 4,
  Friday = 5,
  Saturday = 6,
}

---@param year number
---@param month number
---@param first_day_of_week WeekDay  -- e.g. "Sunday", "Monday", etc.
---@return number -- returns weekday index: 0=first_day_of_week, 6=last_day_of_week
local function get_start_day(year, month, first_day_of_week)
  vim.validate({
    year = { year, 'number' },
    month = { month, 'number' },
    first_day_of_week = {
      first_day_of_week,
      function(val)
        return weekday_map[val] ~= nil
      end,
      'a valid day name (e.g. "Monday")',
    },
  })

  local weekday = tonumber(os.date('%w', os.time({ year = year, month = month, day = 1 })))
  local shift = weekday_map[first_day_of_week]
  return (weekday - shift + 7) % 7
end

---@param first_day_of_week WeekDay -- e.g. "Sunday", "Monday"
---@return string -- e.g. " Mo Tu We Th Fr Sa Su "
local function make_calendar_title(first_day_of_week)
  local days = { 'Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa' }

  vim.validate({
    first_day_of_week = {
      first_day_of_week,
      function(val)
        return weekday_map[val] ~= nil
      end,
      'a valid day name (e.g. "Monday")',
    },
  })

  local start_index = weekday_map[first_day_of_week] -- 0–6
  local result = {}

  for i = 0, 6 do
    local idx = (start_index + i) % 7
    table.insert(result, days[idx + 1])
  end

  return table.concat(result, ' ')
end

local month_names = {
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
}

---@param month_number number
---@return string
local function get_month_name(month_number)
  return month_names[month_number]
end

---@param year number
---@param month number
---@return {[1]:string, [2]:string}[]
local function get_calander_title(year, month)
  local month_name = get_month_name(month)
  local f_str = ' %s %s '
  return { { f_str:format(month_name, year), 'KanbanDatePickerTitle' } }
end

---@param days_in_month number
---@param start_day number
---@param opts {find_day?:number,today_day:number}
local function get_calendar_lines(days_in_month, start_day, opts)
  vim.validate('days_in_month', days_in_month, 'number')
  local lines = {}
  local positions = { first_day = {}, last_day = {}, find_day = nil }

  local line_x = 0
  local line = {}
  local function add_to_line(day)
    line_x = line_x + 1
    table.insert(line, day)
  end

  for _ = 1, start_day do
    add_to_line('  ') -- Empty space for days before start
  end

  for day = 1, days_in_month do
    add_to_line(string.format('%2d', day))
    if day == 1 then
      local col = (line_x * 2) + (line_x - 2 * 1)
      local row = #lines + 1
      positions.first_day = { row = row, col = col }
    end
    if day >= 28 then
      local col = (line_x * 2) + (line_x - 2 * 1)
      local row = #lines + 1
      positions.last_day = { row = row, col = col }
    end
    if type(opts.find_day) == 'number' and opts.find_day == day then
      local col = (line_x * 2) + (line_x - 2 * 1)
      local row = #lines + 1
      positions.find_day = { row = row, col = col }
    end
    if opts.today_day > 0 and opts.today_day == day then
      local col = (line_x * 2) + (line_x - 2 * 1)
      local row = #lines + 1
      positions.today = { row = row, col = col }
    end

    if #line == 7 then
      table.insert(lines, table.concat(line, ' '))
      line_x = 0
      line = {}
    end
  end
  -- last line
  if #line > 0 then
    table.insert(lines, table.concat(line, ' '))
  end

  return lines, positions
end

---@param opts? superkanban.DatePicker.NewOpts
---@param ctx superkanban.Ctx
---@return superkanban.DatePickerUI
function M.new(opts, ctx)
  ---@diagnostic disable-next-line: param-type-mismatch
  local self = setmetatable({}, M)

  opts = opts or {}
  opts.data = opts.data or {}
  self.ctx = ctx

  ---@diagnostic disable-next-line: assign-type-mismatch
  self.current_year, self.current_month, self.current_day =
    tonumber(os.date('%Y')), tonumber(os.date('%m')), tonumber(os.date('%d'))
  -- self.current_year, self.current_month = 1970, tonumber(os.date("%m"))

  self.data = {
    year = opts.data.year or self.current_year,
    month = opts.data.month or self.current_month,
    day = opts.data.day or self.current_day,
  }

  self.win_opts = {
    col = opts.col or 2,
    row = opts.row or 0,
    relative = opts.relative or 'cursor',
  }

  return self
end

---@param find_day? number
function M:scaffold_day_lines(find_day)
  local days_in_month = get_days_in_month(self.data.year, self.data.month)
  local start_day = get_start_day(self.data.year, self.data.month, config.date_picker.first_day_of_week)
  local lines, day_positions = get_calendar_lines(days_in_month, start_day, {
    find_day = find_day,
    today_day = self:month_has_today(),
  })

  return {
    lines = lines,
    day_positions = day_positions,
    height = #lines,
    border_height = #lines + 2,
  }
end

---@param opts superkanban.DatePicker.MountOpts
function M:mount(opts)
  opts = opts or {}
  local conf = config

  local date_selected = false
  local function handle_on_select()
    local date = self:insert_date()
    if opts.on_select and date then
      date_selected = true
      opts.on_select(date)
      self:exit()
    end
  end

  local width = 20
  local border_width = width + 2
  local info = self:scaffold_day_lines(self.data.day)

  local calender_title = make_calendar_title(conf.date_picker.first_day_of_week)
  local weekdays = {
    { { text.center_str(calender_title, border_width), 'KanbanDatePickerWeekDays' } },
    { { text.center_str(string.rep('─', width), border_width), 'KanbanDatePickerSeparator' } },
  }

  self.border_win = Snacks.win({
    -- User cofig values
    border = conf.date_picker.border,
    zindex = conf.date_picker.zindex,
    wo = utils.merge({
      winhighlight = hl.date_picker,
    }, conf.date_picker.win_options),

    width = border_width,
    height = info.border_height,
    col = self.win_opts.col,
    row = self.win_opts.row,
    -- Non cofig values
    title = get_calander_title(self.data.year, self.data.month),
    title_pos = 'center',
    relative = self.win_opts.relative,
    enter = false,
    on_win = function()
      vim.schedule(function()
        self:render_border_win_lines(weekdays)
      end)
    end,
    on_close = function()
      self:exit()
    end,
  })

  self.win = Snacks.win({
    zindex = conf.date_picker.zindex,
    wo = utils.merge({
      winhighlight = hl.date_picker,
    }, conf.date_picker.win_options),

    width = width,
    height = info.height,
    border = 'none',
    relative = 'win',
    -- col = "0",
    row = #weekdays,
    win = self.border_win.win,
    text = function()
      return info.lines
    end,
    on_win = function()
      vim.schedule(function()
        self:hl_a_day(info.day_positions.today)
        self:put_cursor_on_a_day(info.day_positions.find_day)
        self:set_events()
      end)
    end,
    on_close = function()
      self:exit()
      -- Call if user canceled and did not selelcted any date
      if not date_selected and opts.on_close then
        opts.on_close()
      end
    end,
    keys = {
      ['<left>'] = { 'ge', expr = true },
      ['<right>'] = { 'e', expr = true },
      h = { 'ge', expr = true },
      l = { 'e', expr = true },
      b = { 'ge', expr = true },
      w = { 'e', expr = true },
      ['0'] = { '0e', expr = true },
      ['.'] = function()
        self:update_month(self.current_year, self.current_month, { focus_on = 'today' })
      end,
      n = function()
        self:next_month()
      end,
      p = function()
        self:prev_month()
      end,
      i = handle_on_select,
      o = handle_on_select,
    },
  })
end

function M:exit()
  self.win:close()
  self.border_win:close()
end

function M:month_has_today()
  if self.current_year == self.data.year and self.current_month == self.data.month then
    return self.current_day
  end

  return 0
end

---@param pos {row:integer,col:integer}
function M:put_cursor_on_a_day(pos)
  if not pos or not pos.row or not pos.col then
    return
  end
  vim.api.nvim_win_set_cursor(self.win.win, { pos.row, pos.col })
end

---@param pos {row:integer,col:integer}
function M:hl_a_day(pos)
  if not pos or not pos.row or not pos.col then
    return
  end

  vim.api.nvim_buf_set_extmark(0, ns_date_today, pos.row - 1, pos.col - 1, {
    end_col = pos.col + 1,
    hl_group = 'KanbanDatePickerDateToday',
  })
end

---@param year integer
---@param month integer
---@param opts {focus_on?:"first_day"|"last_day"|"today"|number}
function M:update_month(year, month, opts)
  opts = opts or {}
  self.data.month = month
  self.data.year = year

  ---@type any, any
  local find_day, focus_on = nil, opts.focus_on
  if type(opts.focus_on) == 'number' then
    find_day = opts.focus_on
    focus_on = 'find_day'
  end

  local info = self:scaffold_day_lines(find_day)

  -- update height
  vim.api.nvim_win_set_height(self.win.win, info.height)
  vim.api.nvim_win_set_height(self.border_win.win, info.border_height)

  self.border_win:set_title(get_calander_title(year, month))
  vim.api.nvim_buf_set_lines(self.win.buf, 0, -1, false, info.lines)
  self:hl_a_day(info.day_positions.today)
  if focus_on then
    self:put_cursor_on_a_day(info.day_positions[focus_on])
  end
end

function M:next_month()
  local year = self.data.year
  local month = self.data.month + 1
  if month > 12 then
    month = 1
    year = year + 1
  end

  self:update_month(year, month, { focus_on = 'first_day' })
end

function M:prev_month()
  local year = self.data.year
  local month = self.data.month - 1
  if month < 1 then
    month = 12
    year = year - 1
  end

  self:update_month(year, month, { focus_on = 'last_day' })
end

function M:insert_date()
  local day = self:extract_day_under_cursor()
  if not day then
    return
  end
  self.data.day = day

  return self.data
end

function M:cursor_show()
  vim.cmd('highlight! Cursor blend=NONE')
end

function M:cursor_hide()
  vim.cmd('highlight! Cursor blend=100')
end

function M:focus()
  self.win:focus()
end

function M:render_border_win_lines(weekdays)
  text.render_lines(self.border_win.buf, ns_date_picker, weekdays, 0)
end

function M:extract_day_under_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1
  local line = vim.api.nvim_get_current_line()

  -- Match 2-character date fields (e.g., " 1", "22")
  for start_col = 1, #line - 1 do
    local substr = line:sub(start_col, start_col + 1)
    if substr:match('^ ?%d$') or substr:match('^%d%d$') then
      local end_col = start_col + 1
      if col >= start_col - 1 and col <= end_col - 1 then
        -- Extract number & trim space
        return tonumber(substr:match('%d+'))
      end
    end
  end

  return nil
end

function M:highlight_day_under_cursor()
  vim.api.nvim_buf_clear_namespace(0, ns_date_under_cursor, 0, -1) -- Clear previous extmarks

  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  row = row - 1 -- convert to 0-indexed
  local line = vim.api.nvim_get_current_line()

  local selected_date = nil

  -- Match 2-character date fields (e.g., " 1", "22")
  for start_col = 1, #line - 1 do
    local substr = line:sub(start_col, start_col + 1)
    if substr:match('^ ?%d$') or substr:match('^%d%d$') then
      local end_col = start_col + 2 - 1
      if col >= start_col - 1 and col <= end_col - 1 then
        vim.api.nvim_buf_set_extmark(0, ns_date_under_cursor, row, start_col - 1, {
          end_col = end_col,
          hl_group = 'KanbanDatePickerUnderCursor',
        })

        -- Extract number & trim space
        selected_date = tonumber(substr:match('%d+'))
        break
      end
    end
  end

  if selected_date and selected_date > 0 then
    self.data.day = selected_date
  else
    vim.api.nvim_feedkeys('w', 'n', false)
  end
end

function M:set_events()
  self.border_win:on({ 'BufEnter', 'WinEnter' }, function()
    vim.schedule(function()
      self:focus()
    end)
  end, { buf = true })

  self.win:on({ 'CursorMoved' }, function()
    vim.schedule(function()
      self:highlight_day_under_cursor()
    end)
  end, { buf = true })
end

-- local function open_date()
-- 	local picker = M.new({}, _G.foo)
-- 	picker:mount({
-- 		on_select = function(date)
-- 			dd(date)
-- 		end,
-- 		on_close = function()
-- 			dd("closed")
-- 		end,
-- 	})
-- end
-- open_date()

---@param conf superkanban.Config
function M.setup(conf)
  config = conf
end

return M
