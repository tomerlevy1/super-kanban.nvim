---@text 5. Commands ~
---
---     :SuperKanban open                |super-kanban-command-open|
---     :SuperKanban create              |super-kanban-command-create|
---     :SuperKanban list                |super-kanban-command-list|
---     :SuperKanban card                |super-kanban-command-card|
---
--- These commands are provided by |super-kanban.nvim| to control board behavior.
--- Read below for more details on subcommands and their functionality.
---@tag :SuperKanban super-kanban-command
---@toc_entry 5. Commands

--- :SuperKanban [file] ~
--- :SuperKanban open [file] ~
---
---     Open the main Kanban board window with the given file.
---@toc_entry   - SuperKanban open
---@tag super-kanban-command-open

--- :SuperKanban create [file] ~
---
---     Create a new board file.
---     - If no argument is passed, prompts for a file. (TODO: work on this)
---     - You may pass a relative or absolute path like `file.md` or `dir/file.md`.
---@toc_entry   - SuperKanban create
---@tag super-kanban-command-create

--- :SuperKanban list ~
---
---     Perform list-related actions like creating, renaming, deleting,
---     moving, or jumping between lists in the Kanban board.
---
--- Available subcommands: ~
---
--- create=[position]
---   - `begin` : Create a list at the beginning of the board.
---   - `end`   : Create a list at the end of the board.
---
--- rename
---   Rename the currently selected list.
---
--- delete
---   Delete the currently selected list.
---
--- move=[direction]
---   - `left`  : Move the list one position to the left.
---   - `right` : Move the list one position to the right.
---
--- jump=[direction]
---   - `left`  : Jump focus to the list on the left.
---   - `right` : Jump focus to the list on the right.
---   - `begin` : Jump focus to the first list.
---   - `end`   : Jump focus to the last list.
---
--- sort=[option]
---   - `descending` : Sort cards in the list by due date (latest first).
---   - `ascending`  : Sort cards in the list by due date (earliest first).
---@toc_entry   - SuperKanban list
---@tag super-kanban-command-list

--- :SuperKanban card ~
---
---     Perform card-related actions such as creating, moving, jumping,
---     toggling completion, assigning due dates, and more.
---
--- Available subcommands: ~
---
--- create=[position]
---   - `before` : Create a card before the current card.
---   - `after`  : Create a card after the current card.
---   - `top`    : Create a card at the top of the current list.
---   - `bottom` : Create a card at the bottom of the current list.
---
--- delete
---   Delete the currently selected card.
---
--- toggle_complete
---   Toggle the completion status of the card.
---
--- archive
---   Archive the currently selected card.
---
--- pick_date
---   Open the date picker to assign a due date.
---
--- remove_date
---   Remove the due date from the current card.
---
--- search
---   Search for cards globally across the board.
---
--- move=[direction]
---   - `up`     : Move the current card upward within the list.
---   - `down`   : Move the current card downward within the list.
---   - `left`   : Move the card to the previous list.
---   - `right`  : Move the card to the next list.
---
--- jump=[direction]
---   - `up`     : Jump focus to the card above.
---   - `down`   : Jump focus to the card below.
---   - `left`   : Jump to the previous list.
---   - `right`  : Jump to the next list.
---   - `top`    : Jump to the top of the current list.
---   - `bottom` : Jump to the bottom of the current list.
---@toc_entry   - SuperKanban card
---@tag super-kanban-command-card


local utils = require('super-kanban.utils')
local text = require('super-kanban.utils.text')
local actions = require('super-kanban.actions')
local completion = require('super-kanban.command.completion')
local superkanban = require('super-kanban')

---@private
---@type superkanban.Config
local config

---Parse key=value inputs
---@private
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

---@private
---@param fn fun(cardUI:superkanban.cardUI|nil,listUI:superkanban.ListUI|nil,ctx:superkanban.Ctx)
---@param ctx superkanban.Ctx
local function run_action_with_data(fn, ctx)
  local list = ctx.lists[ctx.location.list]
  local card = list.cards[ctx.location.card]
  fn(card, list, ctx)
end

---@private
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

local M = {
  get_completion = completion.get_completion,
}

M._command = function(opts)
  local args = opts.fargs

  local mode, file = args[1], nil

  if M.file_modes[mode] then
    file = args[2]
    M.file_modes[mode](file)
    return
  elseif M.action_groups[mode] then
    if not superkanban.is_opned then
      utils.msg('SuperKanban should be open to perform the action.', 'warn')
      return
    end

    local action_group = M.action_groups[mode]
    local action_key, action_value = parse_key_value(args[2])
    local act_name_from_group

    if type(action_group) == 'table' then
      local group = action_group[action_key]
      act_name_from_group = action_value and group and group[action_value] or group
    else
      act_name_from_group = action_group
    end

    if execute_command(act_name_from_group, superkanban._ctx) then
      return
    end

    utils.msg(('[%s] is not a valid command.'):format(text.trim(opts.args)), 'warn')
  else
    file = args[1]
    M.file_modes.open(file)
  end
end

---@private
---@param conf superkanban.Config
function M.setup(conf)
  config = conf

  local file_modes = {
    open = function(file)
      superkanban.open(file)
    end,
    create = function(file)
      superkanban.create(file)
    end,
  }

  local action_groups = {
    -- search = 'search',
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
      -- pick_date = function()
      --   run_action(actions.pick_date(), superkanban._ctx)
      -- end,
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

  M.file_modes = file_modes
  M.action_groups = action_groups
end

return M
