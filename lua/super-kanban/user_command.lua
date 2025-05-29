local mode_options = { 'open', 'create' }
local modes_map = {}
for _, val in pairs(mode_options) do
  modes_map[val] = true
end

local function get_completion(arg_lead, cmd_line, cursor_pos)
  local split = vim.split(cmd_line, '%s+')
  local arg_count = #split - 1

  if arg_count == 1 then
    local first = split[2]
    -- Suggest modes
    local suggestions = vim.tbl_filter(function(item)
      return vim.startswith(item, arg_lead)
    end, mode_options)

    -- Show files if no mode is selected
    if not vim.tbl_contains(mode_options, first) then
      local file_suggestions = vim.fn.getcompletion(arg_lead, 'file')
      vim.list_extend(suggestions, file_suggestions)
    end

    return suggestions
  elseif arg_count == 2 then
    local mode = split[2]
    if mode == 'open' then
      return vim.fn.getcompletion(arg_lead, 'file')
    elseif mode == 'create' then
      return vim.fn.getcompletion(arg_lead, 'dir')
    end
  end

  return {}
end

local M = {}

---@param kanban superkanban
---@param config superkanban.Config
function M.setup_commands(kanban, config)
  vim.api.nvim_create_user_command('SuperKanban', function(opts)
    local args = opts.fargs

    local mode, file = 'open', nil

    if modes_map[args[1]] then
      mode = args[1]
      file = args[2]
    else
      file = args[1]
    end

    if file then
      file = vim.fs.normalize(file)
    end

    if mode == 'open' then
      kanban.open(file)
    elseif mode == 'create' then
      kanban.create(file)
    end
  end, { nargs = '+', complete = get_completion, desc = 'SuperKanban' })
end

return M
