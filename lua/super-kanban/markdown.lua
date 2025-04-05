local M = {}

----------------------
-- Read markdown
----------------------
M.ops = require("kanban.ops").get_ops({})
M.fn = require("kanban.fn")
M.markdown = require("kanban.markdown")

---@param kanban_md_path string
---@return kanban.Markdown
M.read = function(kanban_md_path)
	local md = M.markdown.reader.read(M, kanban_md_path)
	return md
end

return M
