local hl = require("super-kanban.highlights")
local ui = require("super-kanban.ui")

local M = {}

---@class kanban.Config
---@field list_min_width number
---@field markdown kanban.MarkdownConfig
local config = {
	list_min_width = 32,
	markdown = {
		description_folder = "./tasks/", -- "./"
		list_head = "## ",
		due_head = "@",
		due_style = "{<due>}",
		tag_head = "#",
		tag_style = "<tag>",
		header = {
			"---",
			"",
			"kanban-plugin: basic",
			"",
			"---",
			"",
		},
		footer = {
			"",
			"",
			"%% kanban:settings",
			"```",
			'{"kanban-plugin":"basic"}',
			"```",
			"%%",
		},
	},
}

function M.setup()
	hl.create_winhighlights()
end
M.setup()

--- Open super-kanban
---@param source_path string
function M.open(source_path)
	local md = require("super-kanban.markdown").read(source_path)

	---@type kanban.Ctx
	local ctx = {
		root = ui.root(config),
		source_path = source_path,
		lists = {},
	}

	---@type kanban.TaskList.Ctx[]
	local lists = {}
	local first_task_loc = nil

	-- Setup lists & tasks windows then generate ctx
	for list_index, list_md in ipairs(md.lists) do
		local list = ui.list({
			data = { title = list_md.title },
			index = list_index,
			ctx = ctx,
		}, config)

		---@type kanban.TaskUI[]
		local tasks = {}
		if type(list_md.tasks) == "table" and #list_md.tasks ~= 0 then
			for task_index, task_md in ipairs(list_md.tasks) do
				if first_task_loc == nil then
					first_task_loc = { list_index, task_index }
				end
				local task = ui.task({
					data = task_md,
					index = task_index,
					list_index = list_index,
					list_win = list.win,
          ctx = ctx,
				}, config)
				tasks[task_index] = task
			end
		end

		lists[list_index] = ui.list.gen_list_ctx(list, tasks)
	end

	ctx.lists = lists
	ctx.focus_location = first_task_loc
	ctx.root:init(ctx)
end

-- lua require("super-kanban").open()

return M
