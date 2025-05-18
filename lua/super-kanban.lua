local hl = require("super-kanban.highlights")
local ui = require("super-kanban.ui")

local M = {}

---@class superkanban.Config
---@field list_min_width number
---@field markdown superkanban.MarkdownConfig
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
	local parsed_data = require("super-kanban.parser.markdown").parse_file(source_path)

	---@type superkanban.Ctx
	local ctx = {
		root = ui.root(config),
		source_path = source_path,
		lists = {},
	}

	---@type superkanban.TaskList.Ctx[]
	local lists = {}
	local first_task_loc = nil

	local default_list = { { tasks = {}, title = "todo" } }

	-- Setup lists & tasks windows then generate ctx
	for list_index, list_md in ipairs(parsed_data and parsed_data.lists or default_list) do
		local list = ui.list({
			data = { title = list_md.title },
			index = list_index,
			ctx = ctx,
		}, config)

		---@type superkanban.TaskUI[]
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
	ctx.root:mount(ctx)
end

-- lua require("super-kanban").open()

return M
