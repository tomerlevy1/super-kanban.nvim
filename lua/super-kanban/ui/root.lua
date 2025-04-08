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

---@type kanban.Config
local config

---@param conf kanban.Config
function M.new(conf)
	local self = setmetatable({}, M)

	local root_win = Snacks.win({
		-- file = fname,
		-- width = 0.8,
		-- height = 0.8,
		-- col = 1,
		enter = false,
		width = 0,
		height = 0,
		-- border = "rounded",
		border = { "", " ", "", "", "", "", "", "" },
		focusable = true,
		zindex = 10,
		wo = {
			winhighlight = hls.root,
			winbar = string.format(
				"%%#KanbanWinbar#%%= %%#KanbanFileTitleAlt#%%#KanbanFileTitle#%s%%#KanbanFileTitleAlt#%%#KanbanWinbar# %%=",
				"KanBan"
			),
		},
		bo = {
			modifiable = false,
			filetype = "superkanban_board",
		},
	})

	self.win = root_win
	config = conf
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

function M:exit(ctx)
	require("super-kanban.markdown.writer").write(ctx, config)
	for _, li in ipairs(ctx.lists) do
		li.win:close()
	end
	self.win:close()
end

---@param ctx kanban.Ctx
function M:set_actions(ctx) end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on("WinClosed", function(_, ev)
		self:exit(ctx)
	end, { win = true })

	self.win:on("BufEnter", function()
		vim.defer_fn(function()
			self.win:destroy()
		end, 10)
	end, { buf = true })
end

return M
