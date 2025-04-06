local hls = require("super-kanban.highlights")

---@class kanban.TaskList.Opts
---@field data {title: string}
---@field index number
---@field root kanban.RootUI

---@class kanban.TaskListUI: kanban.TaskList.Opts
---@field win snacks.win
---@overload fun(config :{} , opts: kanban.TaskList.Opts): kanban.TaskListUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@param config any
---@param opts kanban.TaskList.Opts
function M.new(config, opts)
	local self = setmetatable({}, M)

	local list_win = Snacks.win({
		enter = false,
		title = opts.data.title,
		title_pos = "center",
		win = opts.root.win.win,
		height = 0.9,
		width = config.list_min_width,
		row = 1,
		col = 10 + (config.list_min_width + 3) * (opts.index - 1),
		relative = "win",
		border = "rounded",
		focusable = false,
		wo = { winhighlight = hls.list },
		bo = { modifiable = false },
	})

	self.win = list_win
	self.data = opts.data
	self.index = opts.index
	self.root = opts.root

	return self
end

---@param ctx kanban.Ctx
function M:init(ctx)
	self:set_actions(ctx)
	self:set_events(ctx)
end

---@param ctx kanban.Ctx
function M:set_actions(ctx)
	-- map("n", "q", function()
	-- 	for _, li in ipairs(lists) do
	-- 		li.win:close()
	-- 	end
	-- 	root_win:close()
	-- end, { buffer = list.win.buf })
end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on("WinClosed", function(_, ev)
		for _, tk in ipairs(ctx.lists[self.index].tasks) do
			tk.win:close()
		end
	end, { win = true })
end

return M
