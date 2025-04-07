local M = {}

---@param ctx kanban.Ctx
---@param config kanban.Config
function M.write(ctx, config)
	local path = string.gsub(ctx.source_path, "^~", os.getenv("HOME"))
	local file = io.open(path, "w")
	if file == nil then
		vim.api.nvim_echo({ "Error: can't open file!! " .. path }, false, { err = true })
		return
	end

	local list_head = config.markdown.list_head
	local due_head = config.markdown.due_head
	local due_style = config.markdown.due_style
	local tag_head = config.markdown.tag_head
	local tag_style = config.markdown.tag_style

	-- Header
	for i in pairs(config.markdown.header) do
		file:write(config.markdown.header[i] .. "\n")
	end

	-- List
	for i in pairs(ctx.lists) do
		local list = ctx.lists[i]
		file:write("\n" .. list_head .. list.data.title .. "\n")
		-- Task
		for j in pairs(list.tasks) do
			local task = list.tasks[j]
			if task.data.title ~= "" then
				local title_head = "- [" .. task.data.check .. "] "
				local title = title_head .. task.data.title
				file:write("\n" .. title .. "\n")
				-- Due
				for k in pairs(task.data.due) do
					local due = task.data.due[k]
					due = string.gsub(due, due_head, "")
					due = due_head .. string.gsub(due_style, "<due>", due)
					file:write(due .. "\n")
				end
				-- Tag
				for k in pairs(task.data.tag) do
					local tag = task.data.tag[k]
					tag = string.gsub(tag, tag_head, "")
					tag = tag_head .. string.gsub(tag_style, "<tag>", tag)
					file:write(tag .. "\n")
				end
			end
		end
	end

	-- Footer
	for i in pairs(config.markdown.footer) do
		file:write(config.markdown.footer[i] .. "\n")
	end
	vim.api.nvim_echo({ { "kanban saved", "None" } }, false, {})
	file:close()
end

return M
