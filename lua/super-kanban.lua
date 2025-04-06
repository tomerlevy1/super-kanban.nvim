local ui = require("super-kanban.ui")

local M = {}

local config = {
	list_min_width = 32,
}

function M.setup()
	print("setup working")
end

---A hack to Combine list and tasks in a type safe way
---@param list table
---@param tasks kanban.TaskUI
---@return kanban.TaskList.Ctx
local function gen_list_ctx(list, tasks)
	list.tasks = tasks
	return list
end

--- Open super-kanban
---@param kanban_md_path string
function M.open(kanban_md_path)
	local md = require("super-kanban.markdown").read(kanban_md_path)

	local root = ui.root(config)
	---@type kanban.TaskList.Ctx[]
	local lists = {}

	-- Initialize lists & tasks windows then generate ctx
	for list_index, list_md in ipairs(md.lists) do
		local list = ui.list(config, {
			data = { title = list_md.title },
			index = list_index,
			root = root,
		})

		---@type kanban.TaskUI[]
		local tasks = {}
		if type(list_md.tasks) == "table" and #list_md.tasks ~= 0 then
			for task_index, task_md in ipairs(list_md.tasks) do
				local task = ui.task(config, {
					data = task_md,
					index = task_index,
					list_index = list_index,
					list_win = list.win,
					root = root,
				})
				tasks[task_index] = task
			end
		end

		lists[list_index] = gen_list_ctx(list, tasks)
	end

	local task_focused = nil
	---@type kanban.Ctx
	local ctx = { root = root, lists = lists }

	ctx.root:init(ctx)
	for _, list in ipairs(ctx.lists) do
		list:init(ctx)
		for _, task in ipairs(list.tasks) do
			task:init(ctx)

			if task_focused == nil then
				task_focused = task
			end
		end
	end

	if task_focused then
		task_focused.win:focus()
	end
end

-- lua require("super-kanban").open()

return M
