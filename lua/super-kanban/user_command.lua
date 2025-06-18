local utils = require('super-kanban.utils')
local text = require('super-kanban.utils.text')
local actions = require('super-kanban.actions')

---@type superkanban.Config
local config

local directions = { 'left', 'right', 'up', 'down', 'first', 'last' }
local list_directions = { 'left', 'right', 'first', 'last' }
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

local top_level_mode_completion = { 'open', 'create', 'card', 'list' }
local nested_mode_completion = {
  open = function(arg_lead)
    return vim.fn.getcompletion(arg_lead, 'file')
  end,
  create = function(arg_lead)
    return vim.fn.getcompletion(arg_lead, 'dir')
  end,
  card = {
    'create',
    'delete',
    'toggle_complete',
    'archive',
    'pick_date',
    'remove_date',
    'search',
    'move=',
    'jump=',
  },
  list = {
    'create',
    'rename',
    'delete',
    'move=',
    'jump=',
    'sort=',
  },
}

local function get_completion(arg_lead, cmd_line, cursor_pos)
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

    return suggestions

  -- Suggest 2nd level modes
  elseif arg_count == 2 then
    local mode = split[2]
    local action = split[3] -- could be 'jump=' or 'move='

    if mode == 'card' then
      if vim.startswith(action, 'jump=') or vim.startswith(arg_lead, 'jump=') then
        return make_kv_completion('jump=', arg_lead, directions)
      elseif vim.startswith(action, 'move=') or vim.startswith(arg_lead, 'move=') then
        return make_kv_completion('move=', arg_lead, directions)
      end
    end

    if mode == 'list' then
      if vim.startswith(action, 'jump=') or vim.startswith(arg_lead, 'jump=') then
        return make_kv_completion('jump=', arg_lead, list_directions)
      elseif vim.startswith(action, 'move=') or vim.startswith(arg_lead, 'move=') then
        return make_kv_completion('move=', arg_lead, list_directions)
      elseif vim.startswith(action, 'sort=') or vim.startswith(arg_lead, 'sort=') then
        return make_kv_completion('sort=', arg_lead, { 'descending', 'ascending' })
      end
    end

    local option = nested_mode_completion[mode]
    if type(option) == 'function' then
      return option(arg_lead)
    else
      return option
    end
  end

  return {}
end

---Parse key=value inputs
---@param arg_str string
local function parse_key_value(arg_str)
  if arg_str == nil or type(arg_str) ~= 'string' then
    return arg_str, nil
  end
  arg_str = text.trim(arg_str)
  if arg_str == '' then
    return arg_str, nil
  end

  local key, value = string.match(arg_str, '([^=]+)=([^=]+)')
  if key and value then
    return key, value
  end
  return arg_str, nil
end

local M = {}

---@param fn fun(cardUI:superkanban.cardUI|nil,listUI:superkanban.ListUI|nil,ctx:superkanban.Ctx)
---@param ctx superkanban.Ctx
local function run_action_with_data(fn, ctx)
  local list = ctx.lists[ctx.location.list]
  local card = list.cards[ctx.location.card]
  fn(card, list, ctx)
end

---@param action_name string
---@param ctx superkanban.Ctx
local execute_command = function(action_name, ctx)
  if type(action_name) == 'string' then
    local callback = actions[action_name]
    if not callback or not type(callback) == 'function' then
      return false
    end

    run_action_with_data(callback, ctx)

    return true
  elseif type(action_name) == 'function' then
    action_name()
    return true
  end

  return false
end

---@param kanban superkanban
---@param conf superkanban.Config
function M.setup(kanban, conf)
  config = conf

  local file_modes = {
    open = function(file)
      kanban.open(file)
    end,
    create = function(file)
      kanban.create(file)
    end,
  }

  local action_groups = {
    -- search = 'search',
    card = {
      create = 'create_card_at_begin',
      delete = 'delete_card',
      toggle_complete = 'toggle_complete',
      archive = 'archive_card',
      pick_date = 'pick_date',
      remove_date = 'remove_date',
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
        first = 'jump_first',
        last = 'jump_last',
      },
      -- pick_date = function()
      --   run_action(actions.pick_date(), kanban._ctx)
      -- end,
    },
    list = {
      create = 'create_list_at_begin',
      rename = 'rename_list',
      delete = 'delete_list',
      move = { -- move=direction
        left = 'move_list_left',
        right = 'move_list_right',
      },
      jump = { -- jump=direction
        left = 'jump_list_left',
        right = 'jump_list_right',
        first = 'jump_list_first',
        last = 'jump_list_last',
      },
      sort = { -- sort=direction
        descending = 'sort_by_due_descending',
        ascending = 'sort_by_due_ascending',
      },
    },
  }

  vim.api.nvim_create_user_command('SuperKanban', function(opts)
    local args = opts.fargs

    local mode, file = args[1], nil

    if file_modes[mode] then
      file = args[2]
      file_modes[mode](file)
      return
    elseif action_groups[mode] then
      if not kanban.is_opned then
        utils.msg('SuperKanban should be open to perform the action.', 'warn')
        return
      end

      local action_group = action_groups[mode]
      local action_key, action_value = parse_key_value(args[2])
      local act_name_from_group

      if type(action_group) == 'table' then
        local group = action_group[action_key]
        act_name_from_group = action_value and group and group[action_value] or group
      else
        act_name_from_group = action_group
      end

      if execute_command(act_name_from_group, kanban._ctx) then
        return
      end

      utils.msg(('[%s] is not a valid command.'):format(text.trim(opts.args)), 'warn')
    else
      file = args[1]
      file_modes.open(file)
    end
  end, { nargs = '+', complete = get_completion, desc = 'SuperKanban' })
end

return M
