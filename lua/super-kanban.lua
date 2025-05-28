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
		-- border = { "", "", "", "│", "┘", "─", "└", "│" }, -- bottom single
		border = { "", "", "", "│", "╯", "─", "╰", "│" }, -- bottom rounded
		-- border = "rounded",
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
		zindex = 10,
		border = "rounded",
		win_options = {},
		first_day_of_week = "Sunday",
	},
	mappinngs = {
		["gn"] = actions.create_task("first"),
		["gN"] = actions.create_task("last"),
		["gD"] = actions.delete_task(),
		["g."] = actions.sort_tasks_by_due("oldest_first"),
		["g,"] = actions.sort_tasks_by_due("newest_first"),

		["zn"] = actions.create_list("first"),
		["zN"] = actions.create_list("last"),
		["zD"] = actions.delete_list(),
		["zr"] = actions.rename_list(),

		["<C-k>"] = actions.jump("up"),
		["<C-j>"] = actions.jump("down"),
		["<C-h>"] = actions.jump("left"),
		["<C-l>"] = actions.jump("right"),
		["gg"] = actions.jump("first"),
		["G"] = actions.jump("last"),

		["<A-k>"] = actions.move("up"),
		["<A-j>"] = actions.move("down"),
		["<A-h>"] = actions.move("left"),
		["<A-l>"] = actions.move("right"),

		["z0"] = actions.jump_list("first"),
		["z$"] = actions.jump_list("last"),
		["zh"] = actions.move_list("left"),
		["zl"] = actions.move_list("right"),

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

M.is_opned = nil
---@type superkanban.Ctx
local ctx = {}

---@param source_path string
local function open_board(source_path)
	if not vim.uv.fs_stat(source_path) then
		require("super-kanban.utils").msg("File does not exist: " .. source_path, "error")
		return nil
	end

	ctx.board = Board()
	ctx.config = config
	ctx.source_path = source_path
	ctx.lists = {}

	local first_task_loc = nil

	local default_list = { { tasks = {}, title = "todo" } }

	local parsed_data = require("super-kanban.parser.markdown").parse_file(source_path)

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

		ctx.lists[list_index] = List.generate_list_ctx(list, tasks)
	end

	ctx.board:mount(ctx, {
		on_open = function()
			M.is_opned = true
		end,
		on_close = function()
			M.is_opned = false
		end,
	})
end

---Open super-kanban
---@param source_path string
function M.open(source_path)
	if M.is_opned and ctx.source_path == source_path then
		return
	elseif M.is_opned and ctx.board then
		if ctx.board then
			ctx.board:exit()
		end

		vim.schedule(function()
			open_board(source_path)
		end)
		return
	end

	open_board(source_path)
end

-- lua require("super-kanban").open("test.md")

return M
