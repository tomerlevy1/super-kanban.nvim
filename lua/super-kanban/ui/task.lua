local hls = require("super-kanban.highlights")

---@class kanban.Task.Opts
---@field data kanban.TaskData
---@field index number
---@field list_index number
---@field list_win snacks.win
---@field root kanban.RootUI

---@class kanban.TaskUI: kanban.Task.Opts
---@field win snacks.win
---@overload fun(config :{} , opts: kanban.Task.Opts): kanban.TaskUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@param config any
---@param opts kanban.Task.Opts
function M.new(config, opts)
	local self = setmetatable({}, M)

	local task_win = Snacks.win({
		show = false,
		enter = false,
		text = opts.data.title,
		win = opts.list_win.win,
		width = 0,
		height = 4,
		col = 0,
		row = (4 + 1) * (opts.index - 1),
		relative = "win",
		-- border = "rounded",
		border = { "", "", "", " ", "▁", "▁", "▁", " " },
		focusable = true,
		wo = {
			winbar = "%=+",
			winhighlight = hls.task,
		},
		bo = { modifiable = true },
	})

	self.win = task_win
	self.data = opts.data
	self.index = opts.index
	self.list_win = opts.list_win
	self.root = opts.root

	return self
end

---@param ctx kanban.Ctx
function M:init(ctx)
	self.win:show()
	self:set_actions(ctx)
	self:set_events(ctx)
end

---@param ctx kanban.Ctx
function M:set_actions(ctx)
	local buf = self.win.buf
	local map = vim.keymap.set

	map("n", "q", function()
		self.root.win:close()
	end, { buffer = buf })
end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on("BufEnter", function()
		vim.wo.winhighlight = hls.taskActive
	end, { buf = true })

	self.win:on("BufLeave", function()
		vim.wo.winhighlight = hls.task
	end, { buf = true })
end

return M
