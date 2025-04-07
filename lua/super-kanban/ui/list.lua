local hls = require("super-kanban.highlights")

---@class kanban.TaskList.Opts
---@field data {title: string}
---@field index number
---@field root kanban.RootUI

---@class kanban.TaskListUI
---@field data {title: string}
---@field index number
---@field win snacks.win
---@overload fun(opts:kanban.TaskList.Opts,config:{}): kanban.TaskListUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@param opts kanban.TaskList.Opts
---@param config any
function M.new(opts, config)
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
		focusable = true,
		zindex = 15,
		wo = { winhighlight = hls.list },
		bo = { modifiable = true },
	})

	self.win = list_win
	self.data = opts.data
	self.index = opts.index

	return self
end

---@param ctx kanban.Ctx
function M:init(ctx)
	self:set_actions(ctx)
	self:set_events(ctx)
end

---@param ctx kanban.Ctx
function M:set_actions(ctx)
	local buf = self.win.buf
	local map = vim.keymap.set

	local act = self:get_actions(ctx)

	map("n", "q", act.close, { buffer = buf })
end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on("WinClosed", function(_, ev)
		for _, tk in ipairs(ctx.lists[self.index].tasks) do
			tk.win:close()
		end
	end, { win = true })

	self.win:on("BufEnter", function()
		local tk = ctx.lists[self.index].tasks[1]
		if tk then
			tk:focus()
		end
	end, { buf = true })
end

---A hack to Combine list and tasks in a type safe way
---@param list table
---@param tasks kanban.TaskUI
---@return kanban.TaskList.Ctx
function M.gen_list_ctx(list, tasks)
	list.tasks = tasks
	return list
end

function M:get_actions(ctx)
	local act = {
		-- swap_vertical = function(direction)
		-- 	if direction == nil then
		-- 		direction = 1
		-- 	end
		-- 	return function() end
		-- end,
		-- swap_horizontal = function(direction)
		-- 	if direction == nil then
		-- 		direction = 1
		-- 	end
		-- 	return function() end
		-- end,

		close = function()
			ctx.root.win:close()
		end,
	}

	return act
end

return M
