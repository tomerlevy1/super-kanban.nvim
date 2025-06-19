local utils = require('super-kanban.utils')

local M = {}
--------------------------------------------------
---- Markdown Writer -----------------------------
--------------------------------------------------

local function format_task_list_items(items)
  if #items > 0 then
    return ' ' .. table.concat(items, ' ')
  end
  return ''
end

---@param data superkanban.TaskData
local function format_md_checklist(data)
  local tag = format_task_list_items(data.tag)
  local due = format_task_list_items(data.due)
  return string.format('- [%s] %s%s%s\n', data.check, data.title, tag, due)
end

---@param ctx superkanban.Ctx
---@param conf superkanban.Config
function M.write_kanban_file(ctx, conf)
  local file = io.open(ctx.source_path, 'w')
  if not file then
    require('super-kanban.utils').msg("Can't open file.", 'error')
    return nil
  end
  local decorators = conf[ctx.ft]
  local heading_prefix = utils.get_heading_prefix(decorators.list_heading, ctx.ft)

  local new_lines = {}

  for _, list_section in ipairs(ctx.lists) do
    -- Add heading
    table.insert(new_lines, string.format('%s %s\n', heading_prefix, list_section.data.title))

    -- Add Complete mark
    if list_section.complete_task then
      table.insert(new_lines, decorators.list_auto_complete_mark .. '\n')
    end

    -- Add checklist
    for _, card in ipairs(list_section.cards) do
      table.insert(new_lines, format_md_checklist(card.data))
    end
  end

  if ctx.archive and ctx.archive.title == decorators.archive_heading then
    table.insert(new_lines, ('\n%s\n'):format(decorators.section_separators))

    -- Add heading
    table.insert(new_lines, string.format('%s %s\n', heading_prefix, ctx.archive.title))

    -- Add checklist
    for _, task_data in ipairs(ctx.archive.tasks) do
      table.insert(new_lines, format_md_checklist(task_data))
    end
  end

  for _, line in ipairs(new_lines) do
    file:write(line .. '\n')
  end
  file:close()
end

---@param source_path string
---@param lines string[]
function M.write_lines(source_path, lines)
  local file = io.open(source_path, 'w')
  if not file then
    utils.msg('Failed to create file: [' .. source_path .. ']', 'error')
    return
  end

  for _, line in ipairs(lines) do
    file:write(line .. '\n')
  end

  file:close()

  utils.msg('Created file: [' .. source_path .. '].', 'info')
  return true
end

return M
