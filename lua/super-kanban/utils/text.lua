local Date = require('super-kanban.utils.date')
local M = {}

-- local function extract_dates(text)
-- 	local dates = {}
-- 	for date in text:gmatch("(@{%d+[,-/]%d%d?[,-/]%d%d?})") do
-- 		table.insert(dates, date)
-- 	end
-- 	return dates
-- end

-- local function extract_tags(text)
-- 	local tags = {}
-- 	for tag in text:gmatch("#%w+") do
-- 		table.insert(tags, tag)
-- 	end
-- 	return tags
-- end

function M.extract_task_data_from_str(raw)
  local tags = {}
  local due = {}
  local date_obj = nil

  -- extract tags
  local title = raw:gsub('#%S+', function(tag)
    table.insert(tags, tag) -- tag:sub(2) remove '#' prefix
    return ''
  end)
  -- extract dates
  title = title:gsub('(@{%d+[,-/]%d%d?[,-/]%d%d?})', function(date)
    table.insert(due, date)
    return ''
  end)
  -- clean up spaces
  title = title:gsub('%s+', ' '):gsub('^%s*(.-)%s*$', '%1')

  if #due > 0 then
    date_obj = Date.extract_date_obj_from_str(due[#due])
  end

  return title, tags, due, date_obj
end

---@param data superkanban.TaskData
function M.get_buf_lines_from_task(data)
  local lines = { data.title or '' }

  if #data.tag > 0 then
    lines[2] = table.concat(data.tag, ' ')
  end

  if #data.due > 0 then
    if lines[2] then
      lines[2] = lines[2] .. ' ' .. table.concat(data.due, ' ')
    else
      lines[2] = table.concat(data.due, ' ')
    end
  end

  return lines
end

---@param buf number
---@param ns integer
---@param lines HighlightLine
---@param start_line? number 0-index
function M.render_lines(buf, ns, lines, start_line)
  start_line = start_line or 0
  local current_line = start_line

  for _, segments in ipairs(lines) do
    local line = ''
    local col = 0

    -- First pass to build full line
    for _, seg in ipairs(segments) do
      line = line .. seg[1]
    end

    -- Set line in buffer
    vim.api.nvim_buf_set_lines(buf, current_line, current_line + 1, false, { line })

    -- Second pass for highlights
    for _, seg in ipairs(segments) do
      local text, hl_group = seg[1], seg[2]
      vim.api.nvim_buf_set_extmark(buf, ns, current_line, col, {
        end_col = col + #text,
        hl_group = hl_group,
      })
      col = col + #text
    end

    current_line = current_line + 1
  end
end

---@param str string
---@param width number
---@param end_paddig? boolean
---@return string
function M.center_str(str, width, end_paddig)
  local str_len = vim.fn.strdisplaywidth(str)
  if str_len >= width then
    return str
  end

  local left_pad = math.floor((width - str_len) / 2)
  local centered_str = string.rep(' ', left_pad) .. str

  if end_paddig then
    local right_pad = width - str_len - left_pad
    centered_str = centered_str .. string.rep(' ', right_pad)
  end

  return centered_str
end

function M.remove_char_at(str, col)
  return str:sub(1, col - 1) .. str:sub(col + 1)
end

function M.trim(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

function M.find_at_sign_before_cursor()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  if col == 0 then
    return false
  end

  local line = vim.api.nvim_get_current_line()
  local char_before = line:sub(col - 1, col) -- Lua strings are 1-based
  if char_before == ' @' or col == 1 and char_before == '@' then
    return { row = row, col = col }
  end

  return false
end

function M.remove_trailing_or_lonely_at_sign(str)
  -- Remove @ at the end of a word (e.g., "word@ "), but not emails
  str = str:gsub('(%w+)@(%s)', '%1%2')
  str = str:gsub('(%w+)@$', '%1')

  -- Remove lone @ (surrounded by spaces or at start/end)
  str = str:gsub('^[%s]*@[%s]*$', '') -- line is only "@"
  str = str:gsub('(%s)@(%s)', '%1%2') -- space @ space
  str = str:gsub('^@(%s)', '%1') -- starts with "@ "
  str = str:gsub('(%s)@$', '%1') -- ends with " @"
  return str
end

return M
