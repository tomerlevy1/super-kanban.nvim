local ts = vim.treesitter

local M = {}

function M.create_scratch_buffer(filepath)
  -- Load file content from path
  local lines = {}
  for line in io.lines(filepath) do
    table.insert(lines, line)
  end
  -- Create a scratch buffer and load lines
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  return buf
end

function M.get_parser(ft, filepath)
  local buf = M.create_scratch_buffer(filepath)

  local md_parser = ts.get_parser(buf, ft)
  if not md_parser then
    return nil, buf
  end

  local tree = md_parser:parse()[1]
  local root = tree:root()

  return root, buf
end

---@param text string
---@param checkbox string
function M.create_task_data_from_checklist(text, checkbox)
  local title, tags, due, date_obj = require('super-kanban.utils.text').extract_task_data_from_str(text)

  local task = {
    raw = text,
    title = title,
    check = checkbox and checkbox:match('%[(.-)%]') or ' ',
    due = due or {},
    tag = tags or {},
    date = date_obj,
  }

  return task
end

---@param text string
function M.create_list_data(text)
  return { title = text, tasks = {} }
end

return M
