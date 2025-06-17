local common = require('super-kanban.parser.common')
local ts = vim.treesitter

-- Tree-sitter query to extract tasks and headings
local query = vim.treesitter.query.parse(
  'markdown',
  [[
  (atx_heading (inline) @heading_text)

  (list_item
    [
      (task_list_marker_checked)
      (task_list_marker_unchecked)
    ] @checkbox
    (paragraph (inline) @task_text))

  (paragraph
    (inline) @maybe_bold)
  ]]
)
-- (atx_heading (atx_h2_marker) (inline) @heading_text)
-- (atx_heading (inline) @heading_text)

local M = {}

---@param filepath string
---@param config  superkanban.Config
---@return superkanban.SourceData?
function M.parse_file(filepath, config)
  local root, buf = common.get_parser('markdown', filepath)
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
      if text == config.markdown.archive_heading then
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
      and text == config.markdown.list_auto_complete_mark
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

return M
