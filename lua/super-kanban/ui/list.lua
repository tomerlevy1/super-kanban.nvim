local hls = require("super-kanban.highlights")

local M = {}

---@param config any
---@param list kanban.TaskListMD
---@param index number
---@param root_win snacks.win
---@return snacks.win
function M.get_win(config, list, index, root_win)
	return Snacks.win({
		enter = false,
		-- title = " " .. list.name .. " ",
		title = list.title,
		-- title = "adf",
		title_pos = "center",
		-- file = fname,
		win = root_win.win,
		height = 0.9,
		width = config.list_min_width,
		row = 1,
		col = 10 + (config.list_min_width + 3) * (index - 1),
		relative = "win",
		border = "rounded",
		focusable = false,
		wo = { winhighlight = hls.list },
		-- footer = string.format(" %s ", vim.fn.fnamemodify(fname, ":t")),
		-- footer_pos = "center",
		bo = { modifiable = false },
	})
end

return M
