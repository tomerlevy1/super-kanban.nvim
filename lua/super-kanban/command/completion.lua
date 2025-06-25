local M = {}

local function make_kv_completion(prefix, arg_lead, completions)
  return vim.tbl_filter(
    function(item)
      return vim.startswith(prefix .. item, arg_lead)
    end,
    vim.tbl_map(function(dir)
      return prefix .. dir
    end, completions)
  )
end

local top_level_mode_completion = { 'open', 'create', 'close', 'card', 'list' }
local nested_mode_completion = {
  open = function(arg_lead)
    return vim.fn.getcompletion(arg_lead, 'file')
  end,
  create = function(arg_lead)
    return vim.fn.getcompletion(arg_lead, 'dir')
  end,
  card = {
    'create=',
    'delete',
    'toggle_complete',
    'archive',
    'pick_date',
    'remove_date',
    'open_note',
    'search',
    'move=',
    'jump=',
  },
  list = {
    'create=',
    'rename',
    'delete',
    'move=',
    'jump=',
    'sort=',
  },
}

local function concat_list(list)
  return table.concat(list, '\n')
end

function M.get_completion(arg_lead, cmd_line, cursor_pos)
  local candidates = {}
  local split = vim.split(cmd_line, '%s+')
  local arg_count = #split - 1

  -- Suggest top level modes
  if arg_count == 1 then
    local first = split[2]
    local suggestions = vim.tbl_filter(function(item)
      return vim.startswith(item, arg_lead)
    end, top_level_mode_completion)

    -- Show files if no mode is selected
    if not vim.tbl_contains(top_level_mode_completion, first) then
      local file_suggestions = vim.fn.getcompletion(arg_lead, 'file')
      vim.list_extend(suggestions, file_suggestions)
    end

    return concat_list(suggestions)

  -- Suggest 2nd level modes
  elseif arg_count == 2 then
    local mode = split[2]
    local action = split[3] -- could be 'jump=' or 'move='

    if mode == 'card' then
      if vim.startswith(action, 'jump=') or vim.startswith(arg_lead, 'jump=') then
        return concat_list(make_kv_completion('jump=', arg_lead, { 'up', 'down', 'left', 'right', 'top', 'bottom' }))
      elseif vim.startswith(action, 'move=') or vim.startswith(arg_lead, 'move=') then
        return concat_list(make_kv_completion('move=', arg_lead, { 'up', 'down', 'left', 'right' }))
      elseif vim.startswith(action, 'create=') or vim.startswith(arg_lead, 'create=') then
        return concat_list(make_kv_completion('create=', arg_lead, { 'before', 'after', 'top', 'bottom' }))
      end
    end

    if mode == 'list' then
      if vim.startswith(action, 'jump=') or vim.startswith(arg_lead, 'jump=') then
        return concat_list(make_kv_completion('jump=', arg_lead, { 'left', 'right', 'begin', 'end' }))
      elseif vim.startswith(action, 'move=') or vim.startswith(arg_lead, 'move=') then
        return concat_list(make_kv_completion('move=', arg_lead, { 'left', 'right' }))
      elseif vim.startswith(action, 'sort=') or vim.startswith(arg_lead, 'sort=') then
        return concat_list(make_kv_completion('sort=', arg_lead, { 'descending', 'ascending' }))
      elseif vim.startswith(action, 'create=') or vim.startswith(arg_lead, 'create=') then
        return concat_list(make_kv_completion('create=', arg_lead, { 'begin', 'end' }))
      end
    end

    local option = nested_mode_completion[mode]
    if type(option) == 'function' then
      return concat_list(option(arg_lead))
    else
      return concat_list(option)
    end
  end

  return table.concat(candidates, '\n')
end

return M
