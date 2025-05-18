local M = {}

M.get_default = function(x, default)
	return M.if_nil(x, default, x)
end

M.if_nil = function(x, was_nil, was_not_nil)
	if x == nil then
		return was_nil
	else
		return was_not_nil
	end
end

---@param msg string
---@param level? "trace"|"debug"|"info"|"warn"|"error"
M.msg = function(msg, level)
	vim.notify(msg, level, { title = "Super Kanban" })
end


return M
