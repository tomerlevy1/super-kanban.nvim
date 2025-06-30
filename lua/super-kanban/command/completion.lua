local superkanban = require('super-kanban')

local M = {
  path_arguments = {},
  file_arguments = {},
  list_arguments = {},
}
---@class superkanban.completin_levels
---@field mode string[] List of top-level modes or commands (e.g., 'open', 'card', 'list')
---@field subcommands any[]
---@field subcommand_values table<string, table<string, string[]>>
M.completins = {
  -- Example: { 'open', 'close', 'create', 'card', 'list' }
  mode = {},

  -- Maps each mode to a list of available subcommands, or a function that returns them.
  -- Example:
  --   card = { 'create=', 'jump=', 'delete' }
  --   open = function(arg_lead) return vim.fn.getcompletion(...) end
  subcommands = {},

  -- Maps subcommand keys to their possible values.
  -- Example:
  --   card = {
  --     ['create='] = { 'before', 'bottom', 'top', 'after' },
  --     ['jump='] = { 'up', 'down', 'left', 'right' },
  --   }
  subcommand_values = {},
}

local function concat_list(list)
  return table.concat(list, '\n')
end

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

function M.get_completion(arg_lead, cmd_line, cursor_pos)
  local candidates = {}
  local split = vim.split(cmd_line, '%s+')
  local arg_count = #split - 1

  -- Suggest top level modes
  if arg_count == 1 then
    -- local first = split[2]
    local suggestions = vim.tbl_filter(function(item)
      return vim.startswith(item, arg_lead)
    end, M.completins.mode)

    -- -- Show files if no mode is selected
    -- if not vim.tbl_contains(M.completin_levels.first, first) then
    --   local file_suggestions = vim.fn.getcompletion(arg_lead, 'file')
    --   vim.list_extend(suggestions, file_suggestions)
    -- end

    return concat_list(suggestions)

  -- Suggest 2nd level subcommands
  elseif arg_count == 2 then
    local mode = split[2]
    local action = split[3] -- could be 'jump=' or 'move='

    -- Get subcommand_values
    local mode_completions = M.completins.subcommand_values[mode]
    for prefix, values in pairs(mode_completions or {}) do -- prefix: 'jump='
      if vim.startswith(action, prefix) or vim.startswith(arg_lead, prefix) then
        return concat_list(make_kv_completion(prefix, arg_lead, values))
      end
    end

    local option = M.completins.subcommands[mode]
    if type(option) == 'function' then
      return concat_list(option(arg_lead))
    else
      return concat_list(option)
    end
  end

  return table.concat(candidates, '\n')
end

---@private
---@param conf superkanban.Config
function M.setup(conf)
  M.path_arguments = {
    create = function(...)
      superkanban.create(...)
    end,
  }

  M.file_arguments = {
    open = function(...)
      superkanban.open(...)
    end,
  }

  M.list_arguments = {
    close = 'close',
    card = {
      create = {
        before = 'create_card_before',
        after = 'create_card_after',
        top = 'create_card_top',
        bottom = 'create_card_bottom',
      },
      delete = 'delete_card',
      toggle_complete = 'toggle_complete',
      archive = 'archive_card',
      pick_date = 'pick_date',
      remove_date = 'remove_date',
      open_note = 'open_note',
      search = 'search_card',
      move = { -- move=direction
        up = 'move_up',
        down = 'move_down',
        left = 'move_left',
        right = 'move_right',
      },
      jump = { -- jump=direction
        up = 'jump_up',
        down = 'jump_down',
        left = 'jump_left',
        right = 'jump_right',
        top = 'jump_top',
        bottom = 'jump_bottom',
      },
    },
    list = {
      create = {
        begin = 'create_list_at_begin',
        ['end'] = 'create_list_at_end',
      },
      rename = 'rename_list',
      delete = 'delete_list',
      move = { -- move=direction
        left = 'move_list_left',
        right = 'move_list_right',
      },
      jump = { -- jump=direction
        left = 'jump_list_left',
        right = 'jump_list_right',
        begin = 'jump_list_begin',
        ['end'] = 'jump_list_end',
      },
      sort = { -- sort=direction
        descending = 'sort_by_due_descending',
        ascending = 'sort_by_due_ascending',
      },
    },
  }

  for key, _ in pairs(M.file_arguments) do
    table.insert(M.completins.mode, key)
    M.completins.subcommands[key] = function(arg_lead)
      return vim.fn.getcompletion(arg_lead, 'file')
    end
  end

  for key, _ in pairs(M.path_arguments) do
    table.insert(M.completins.mode, key)
    M.completins.subcommands[key] = function(arg_lead)
      return vim.fn.getcompletion(arg_lead, 'dir')
    end
  end

  -- Build completion levels and argument completions from list_arguments
  for mode, subcommands in pairs(M.list_arguments) do
    table.insert(M.completins.mode, mode)

    if type(subcommands) == 'table' then
      M.completins.subcommands[mode] = {}

      for name, value in pairs(subcommands) do
        local is_nested = type(value) == 'table'
        local item_name = is_nested and (name .. '=') or name

        table.insert(M.completins.subcommands[mode], item_name)

        if is_nested and type(value) == 'table' then
          M.completins.subcommand_values[mode] = M.completins.subcommand_values[mode] or {}
          M.completins.subcommand_values[mode][item_name] = vim.tbl_keys(value)
        end
      end
    end
  end
end

return M
