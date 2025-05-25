local hl = require("super-kanban.highlights")
local Board = require("super-kanban.ui.board")
local List = require("super-kanban.ui.list")
local Task = require("super-kanban.ui.task")
local actions = require("super-kanban.actions")

local M = {}

---@class superkanban.Config
---@field markdown superkanban.MarkdownConfig
local config = {
	markdown = {
		description_folder = "./tasks/", -- "./"
		list_head = "##",
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
	task = {
		width = 0,
		height = 6,
		zindex = 5,
		border = { "", "", "", " ", "▁", "▁", "▁", " " }, -- add border at bottom
		win_options = {
			wrap = true,
			-- spell = true, Uncomment this to enable spell checking
		},
	},
	list = {
		width = 32,
		height = 0.9,
		zindex = 5,
		border = "rounded",
		win_options = {},
	},
	board = {
		width = 0,
		height = vim.o.lines - 2,
		zindex = 5,
		border = { "", " ", "", "", "", "", "", "" }, -- add empty space on top border
		win_options = {},
		padding = { top = 1, left = 8 },
	},
	date_picker = {
		zindex = 5,
		border = "rounded",
		win_options = {},
		first_day_of_week = "Sunday",
	},
	mappinngs = {
		["gn"] = actions.create_task(),
		["gD"] = actions.delete_task(),

		["zn"] = actions.create_list(),
		["zD"] = actions.delete_list(),
		["zr"] = actions.rename_list(),

		["<C-k>"] = actions.jump("up"),
		["<C-j>"] = actions.jump("down"),
		["<C-h>"] = actions.jump("left"),
		["<C-l>"] = actions.jump("right"),
		["gg"] = actions.jump("first"),
		["G"] = actions.jump("last"),

		["<A-k>"] = actions.swap("up"),
		["<A-j>"] = actions.swap("down"),
		["<A-h>"] = actions.swap("left"),
		["<A-l>"] = actions.swap("right"),

		["z0"] = actions.jump_list("first"),
		["z$"] = actions.jump_list("last"),
		["zh"] = actions.swap_list("left"),
		["zl"] = actions.swap_list("right"),

		["q"] = actions.close(),
		["/"] = actions.search(),
		["zi"] = actions.pick_date(),
		["X"] = actions.log_info(),
	},
}

function M.setup()
	hl.create_winhighlights()
end
-- M.setup()

---Open super-kanban
---@param source_path string
function M.open(source_path)
	local parsed_data = require("super-kanban.parser.markdown").parse_file(source_path)

	---@type superkanban.Ctx
	local ctx = {
		board = Board(config),
		config = config,
		source_path = source_path,
		lists = {},
	}

	---@type superkanban.TaskList.Ctx[]
	local lists = {}
	local first_task_loc = nil

	local default_list = { { tasks = {}, title = "todo" } }

	-- Setup lists & tasks windows then generate ctx
	for list_index, list_md in ipairs(parsed_data and parsed_data.lists or default_list) do
		local list = List({
			data = { title = list_md.title },
			index = list_index,
			ctx = ctx,
		})

		---@type superkanban.TaskUI[]
		local tasks = {}
		if type(list_md.tasks) == "table" and #list_md.tasks ~= 0 then
			for task_index, task_md in ipairs(list_md.tasks) do
				if first_task_loc == nil then
					first_task_loc = { list_index, task_index }
				end
				tasks[task_index] = Task({
					data = task_md,
					index = task_index,
					list_index = list_index,
					ctx = ctx,
				})
			end
		end

		lists[list_index] = List.generate_list_ctx(list, tasks)
	end

	ctx.lists = lists
	ctx.board:mount(ctx)
end

-- lua require("super-kanban").open()

return M
