local hls = require("super-kanban.highlights")

---@class kanban.Task.Opts
---@field md kanban.TaskMD
---@field index number
---@field list_win snacks.win
---@field root_win snacks.win

---@class kanban.Task: kanban.Task.Opts
---@field win snacks.win
---@overload fun(config :{} , opts: kanban.Task.Opts): kanban.Task
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@param config any
---@param opts kanban.Task
function M.new(config, opts)
	local self = setmetatable(opts, M)

	local task_win = Snacks.win({
		enter = false,
		text = opts.md.title,
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

	self:set_actions()
	self:set_events()
	return self
end

function M:set_actions()
	vim.keymap.set("n", "q", function()
		self.root_win:close()
	end, { buffer = self.win.buf })
end

function M:set_events()
	local buf = self.win.buf

	self.win:on("BufEnter", function()
		vim.wo.winhighlight = hls.taskActive
	end, { buffer = buf })

	self.win:on("BufLeave", function()
		vim.wo.winhighlight = hls.task
	end, { buffer = buf })
end

return M
