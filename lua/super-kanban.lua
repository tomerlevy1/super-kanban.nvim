local ui = require("super-kanban.ui")

local M = {}

local config = {
	list_min_width = 32,
}

function M.setup()
	print("setup working")
end

--- Open super-kanban
---@param kanban_md_path string
function M.open(kanban_md_path)
	local md = require("super-kanban.markdown").read(kanban_md_path)

	local root = ui.root(config)
	---@type kanban.TaskList.Ctx[]
	local lists = {}

	-- Setup lists & tasks windows then generate ctx
	for list_index, list_md in ipairs(md.lists) do
		local list = ui.list({
			data = { title = list_md.title },
			index = list_index,
			root = root,
		}, config)

		---@type kanban.TaskUI[]
		local tasks = {}
		if type(list_md.tasks) == "table" and #list_md.tasks ~= 0 then
			for task_index, task_md in ipairs(list_md.tasks) do
				local task = ui.task({
					data = task_md,
					index = task_index,
					list_index = list_index,
					list_win = list.win,
					root = root,
				}, config)
				tasks[task_index] = task
			end
		end

		lists[list_index] = ui.list.gen_list_ctx(list, tasks)
	end

	root:init({ root = root, lists = lists })
end

-- lua require("super-kanban").open()

return M
