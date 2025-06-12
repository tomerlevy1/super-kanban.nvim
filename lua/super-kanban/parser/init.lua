local M = {}

---@param filepath string
---@param filetype  superkanban.ft
---@return superkanban.SourceData?
function M.parse_file(filepath, filetype)
  if filetype == 'markdown' then
    return require('super-kanban.parser.markdown').parse_file(filepath)
  elseif true then
    return require('super-kanban.parser.org').parse_file(filepath)
  end
  return nil
end

return M
