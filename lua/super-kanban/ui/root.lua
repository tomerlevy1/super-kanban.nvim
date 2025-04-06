local hls = require("super-kanban.highlights")

---@class kanban.RootUI
---@field win snacks.win
---@overload fun(config :{}): kanban.RootUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@param config any
function M.new(config)
	local self = setmetatable({}, M)

	local root_win = Snacks.win({
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

	self.win = root_win
	return self
end

---@param ctx kanban.Ctx
function M:init(ctx)
	self:set_actions(ctx)
	self:set_events(ctx)

	local task_focused = nil

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

---@param ctx kanban.Ctx
function M:set_actions(ctx) end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on("WinClosed", function(_, ev)
		for _, li in ipairs(ctx.lists) do
			li.win:close()
		end
	end, { win = true })
end

return M
