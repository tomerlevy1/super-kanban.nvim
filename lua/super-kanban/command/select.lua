local completion = require('super-kanban.command.completion')
local superkanban = require('super-kanban')
local command = require('super-kanban.command')
local utils = require('super-kanban.utils')

local M = {}

--- Convert 'list move=left' => {'list', 'move', 'left'}
local function parse_command(str)
  local parts = vim.split(str, '%s+')
  local result = {}

  for _, part in ipairs(parts) do
    local key, value = part:match('([^=]+)=([^=]+)')
    if key and value then
      table.insert(result, key)
      table.insert(result, value)
    else
      table.insert(result, part)
    end
  end

  return result
end

function M.select_subcmd(actions)
  vim.ui.select(actions, { prompt = 'super-kanban' }, function(value)
    if not value then
      return
    end

    local cmds = parse_command(value)
    if #cmds == 0 then
      return
    end
    local found_action = nil

    local subcommands = completion.list_arguments[cmds[1]][cmds[2]]
    if type(subcommands) == 'string' then
      found_action = subcommands
    elseif subcommands[cmds[3]] and type(subcommands[cmds[3]]) == 'string' then
      found_action = subcommands[cmds[3]]
    end
    if found_action == nil then
      return
    end

    if not superkanban.is_opned then
      utils.msg('SuperKanban should be open to perform the action.', 'warn')
      return
    end

    command.execute_command(found_action, superkanban._ctx)
  end)
end

function M.select()
  vim.ui.select(completion.completins.mode, { prompt = 'super-kanban' }, function(value)
    if not value then
      return
    end

    local subcommands = completion.completins.subcommands[value]
    if type(subcommands) ~= 'table' or #subcommands == 0 then
      command.execute_command(value, superkanban._ctx)
      return
    end

    local all_subcmds = {}

    local subcommand_values = completion.completins.subcommand_values[value]
    for _, subcmd in ipairs(subcommands) do
      if subcommand_values[subcmd] then
        for _, subcmd_value in ipairs(subcommand_values[subcmd]) do
          table.insert(all_subcmds, table.concat({ value, ' ', subcmd, subcmd_value }))
        end
      else
        table.insert(all_subcmds, table.concat({ value, ' ', subcmd }))
      end
    end

    M.select_subcmd(all_subcmds)
  end)
end

return M
