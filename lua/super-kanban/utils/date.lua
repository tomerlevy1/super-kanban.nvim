local M = {}

local current_century = math.floor(os.date('*t').year / 100) * 100
---Normalize short years like 25 → 2025
function M.normalize_year(year)
  return (year < 100) and (current_century + year) or year
end

-- Helper to get comparable timestamp
function M.get_due_timestamp(date)
  if not date then
    return nil
  end

  return os.time({ year = date.year, month = date.month, day = date.day })
end

---@param date_str string
---@return superkanban.DatePickerData|nil
function M.extract_date_obj_from_str(date_str)
  if not date_str then
    return nil
  end

  local year, month, day = date_str:match('(%d+)[,-/](%d+)[,-/](%d+)')
  local y = M.normalize_year(tonumber(year))

  return { year = y, month = tonumber(month), day = tonumber(day) }
end

---@param date superkanban.DatePickerData
---@return string
function M.format_to_date_str(date)
  local f_date = '@{%d/%d/%d}'
  return f_date:format(date.year, date.month, date.day)
end

---@param date superkanban.DatePickerData
---@return string
---@return boolean
function M.get_relative_time(date)
  local y = M.normalize_year(date.year)
  local target_time = os.time({ year = y, month = date.month, day = date.day, hour = 0 })

  local now = os.date('*t')
  local current_time = os.time({ year = now.year, month = now.month, day = now.day, hour = 0 })

  local diff = os.difftime(target_time, current_time)
  local days = math.floor(diff / (60 * 60 * 24))
  local abs_days = math.abs(days)
  -- local years = math.floor(abs_days / 365)
  -- local months = math.floor((abs_days % 365) / 30)
  -- local remaining_days = abs_days % 30

  ---@return string|nil
  local function pluralize(value, unit)
    if value == 0 then
      return nil
    end
    return value .. ' ' .. unit .. (value == 1 and '' or 's')
  end

  local formatted_days = nil
  if abs_days >= 365 then
    formatted_days = pluralize(math.floor(abs_days / 365), 'year')
  elseif abs_days >= 30 then
    formatted_days = pluralize(math.floor(abs_days / 30), 'month')
  else
    formatted_days = pluralize(abs_days % 30, 'day')
  end

  local prefix = days == 0 and 'today' or days > 0 and 'In ' or ''
  local suffix = days < 0 and ' ago' or ''

  local result
  if days == 0 or formatted_days == nil then
    result = 'Today'
  else
    result = prefix .. formatted_days .. suffix
  end

  local is_future = days > 0
  return result, is_future
end

return M
