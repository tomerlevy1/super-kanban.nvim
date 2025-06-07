local utils = require('super-kanban.utils')
local actions = require('super-kanban.actions')

local top_level_mode_completion = { 'open', 'create', 'task', 'list' }
local nested_mode_completion = {
  open = function(arg_lead)
    return vim.fn.getcompletion(arg_lead, 'file')
  end,
  create = function(arg_lead)
    return vim.fn.getcompletion(arg_lead, 'dir')
  end,
  task = { 'pick_date', 'remove_date' },
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
    local option = nested_mode_completion[mode]
    if type(option) == 'function' then
      return option(arg_lead)
    else
      return option
    end
  end

  return {}
end

local M = {}

---@param act {callback:fun(cardUI:superkanban.cardUI|nil,listUI:superkanban.ListUI|nil,ctx:superkanban.Ctx)}
---@param ctx superkanban.Ctx
local function run_action(act, ctx)
  if not act or not act.callback then
    return
  end

  local list = ctx.lists[ctx.location.list]
  local card = list.cards[ctx.location.card]
  act.callback(card, list, ctx)
end

---@param action_key string
---@param ctx superkanban.Ctx
local function run_action_from_key(action_key, ctx)
  if not action_key then
    return
  end

  local fn = actions[action_key]
  if not fn or not type(fn) == 'function' then
    return
  end

  run_action(fn(), ctx)
end

---@param kanban superkanban
---@param config superkanban.Config
function M.setup_commands(kanban, config)
  local file_modes = {
    open = function(file)
      kanban.open(file)
    end,
    create = function(file)
      kanban.create(file)
    end,
  }

  local action_modes = {
    task = {
      pick_date = 'pick_date',
      remove_date = 'remove_date',
      -- pick_date = function()
      --   run_action(actions.pick_date(), kanban._ctx)
      -- end,
    },
    -- list = {
    --   create = function(file)
    --     dd('asdf')
    --   end,
    -- },
  }

  vim.api.nvim_create_user_command('SuperKanban', function(opts)
    local args = opts.fargs

    local mode, file, action = args[1], nil, nil

    if file_modes[mode] then
      file = args[2]
      file_modes[mode](file)
      return
    elseif action_modes[mode] then
      if not kanban.is_opned then
        utils.msg('SuperKanban should be open to perform the action', 'warn')
        return
      end

      action = args[2]
      if action_modes[mode][action] then
        local fn = action_modes[mode][action]
        if type(fn) == 'string' then
          run_action_from_key(fn, kanban._ctx)
        elseif type(fn) == 'function' then
          action_modes[mode][action]()
        end
      end
      return
    else
      file = args[1]
      file_modes.open(file)
    end
  end, { nargs = '+', complete = get_completion, desc = 'SuperKanban' })
end

return M
