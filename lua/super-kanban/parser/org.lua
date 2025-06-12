local common = require('super-kanban.parser.common')
local ts = vim.treesitter

-- Tree-sitter query to extract tasks and headings
local query = vim.treesitter.query.parse(
  'org',
  [[
  (headline
    stars: (stars)
    item: (item) @heading_text)

  (listitem
    bullet: (bullet)
    checkbox: (checkbox) @checkbox
    contents: (paragraph
      (expr)
      (expr)?) @task_text)  ; Support one or two expr nodes in contents

  (body (paragraph
    (expr) @maybe_bold))
  ]]
)

local M = {}

---@param filepath string
---@param config  superkanban.Config
---@return superkanban.SourceData?
function M.parse_file(filepath, config)
  local root, buf = common.get_parser('org', filepath)
  if not root then
    return nil
  end

  ---@type integer|string,integer|string
  local list_index, list_index_before_archive = 0, 0
  ---@type superkanban.SourceData
  local data = {
    lists = {},
  }

  -- Temporarily hold task info until both parts are seen
  local pending_task = {}

  -- Iterate query captures
  for id, node in query:iter_captures(root, buf) do
    local name = query.captures[id]
    local text = ts.get_node_text(node, buf)

    if name == 'heading_text' then
      -- Store the archive data into archive key
      if text == config.org.archive_heading then
        list_index_before_archive = list_index
        list_index = 'archive'
      else
        if type(list_index) == 'string' then
          list_index = list_index_before_archive
        end
        list_index = list_index + 1
      end
      data.lists[list_index] = common.create_list_data(text)
    elseif
      #data.lists[list_index].tasks == 0
      and name == 'maybe_bold'
      and text == config.org.list_auto_complete_mark
    then
      -- Parse bold text with Complete
      data.lists[list_index].complete_task = true
    elseif name == 'checkbox' then
      pending_task.checkbox = text
    elseif name == 'task_text' then
      table.insert(data.lists[list_index].tasks, common.create_task_data_from_checklist(text, pending_task.checkbox))
      pending_task = {}
    end
  end

  -- Delete the buffer once done
  vim.api.nvim_buf_delete(buf, { force = true })
  return data
end

-- local filepath = 'test.org'
-- local data = M.parse_file(filepath)
-- dd(data)
-- M:write_file(filepath, data)

-- -- Print the result
-- for _, list in ipairs(data) do
-- 	print("## " .. list.title)
-- 	for _, task in ipairs(list.tasks) do
-- 		print("- " .. task.check .. " " .. task.title)
-- 	end
-- end

return M
