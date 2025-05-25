local M = {}

function M.get_default(x, default)
	return M.if_nil(x, default, x)
end

function M.if_nil(x, was_nil, was_not_nil)
	if x == nil then
		return was_nil
	else
		return was_not_nil
	end
end

---@param msg string
---@param level? "trace"|"debug"|"info"|"warn"|"error"
function M.msg(msg, level)
	vim.notify(msg, level, { title = "SuperKanban" })
end

function M.is_cursor_at_last_column(col)
	local line = vim.api.nvim_get_current_line()
	return col >= #line
end

function M.merge(default, override)
	return vim.tbl_extend("force", default, override)
end

return M
