local hls = require("super-kanban.highlights")

local M = {}

---@param config any
---@return snacks.win
function M.get_win(config)
	return Snacks.win({
		-- file = fname,
		-- width = 0.8,
		-- height = 0.8,
		-- col = 1,
		width = 0,
		height = 0,
		-- border = "rounded",
		border = { "", " ", "", "", "", "", "", "" },
		focusable = false,
		wo = {
			winhighlight = hls.root,
			winbar = string.format(
				"%%#KanbanWinbar#%%= %%#KanbanFileTitleAlt#%%#KanbanFileTitle#%s%%#KanbanFileTitleAlt#%%#KanbanWinbar# %%=",
				"KanBan"
			),
		},
	})
end

return M
