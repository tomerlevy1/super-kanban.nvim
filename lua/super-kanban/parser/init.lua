local M = {}

---@param filepath string
---@param filetype  superkanban.ft
---@param config  superkanban.Config
---@return superkanban.SourceData?
function M.parse_file(filepath, filetype, config)
  if filetype == 'markdown' then
    return require('super-kanban.parser.markdown').parse_file(filepath, config)
  elseif filetype == 'org' then
    return require('super-kanban.parser.org').parse_file(filepath, config)
  end
  return nil
end

return M
