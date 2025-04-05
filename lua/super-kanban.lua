local ui = require("super-kanban.ui")

local M = {}

local map = vim.keymap.set

local config = {
	list_min_width = 32,
}

function M.setup()
	print("setup working")
end

--- Open super-kanban
---@param kanban_md_path string
function M.open(kanban_md_path)
	local root_win = ui.root.get_win(config)

	local md = require("super-kanban.markdown").read(kanban_md_path)
	local task_focused = nil

	---@type snacks.win[]
	local list_wins = {}
	for list_idx, list_md in ipairs(md.lists) do
		local list_win = ui.list.get_win(config, list_md, list_idx, root_win)
		list_wins[list_idx] = list_win

		---@type kanban.Task[]
		local task_wins = {}
		if type(list_md.tasks) == "table" and #list_md.tasks ~= 0 then
			for task_idx, task_md in ipairs(list_md.tasks) do
				local task = ui.task(config, {
					md = task_md,
					index = task_idx,
					list_win = list_win,
					root_win = root_win,
				})
				task_wins[task_idx] = task

				if task_focused == nil then
					task_focused = task
				end
			end
		end

		list_win:on("WinClosed", function(_, ev)
			for _, tk in ipairs(task_wins) do
				tk.win:close()
			end
		end, { win = true })

		map("n", "q", function()
			for _, li in ipairs(list_wins) do
				li:close()
			end
			root_win:close()
		end, { buffer = list_win.buf })
	end

	if task_focused then
		task_focused.win:focus()
	end

	root_win:on("WinClosed", function(_, ev)
		for _, li in ipairs(list_wins) do
			li:close()
		end
	end, { win = true })
end

-- dd("super-kanban 10")
-- lua require("super-kanban").open()

return M
