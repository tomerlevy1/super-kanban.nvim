local hl = require("super-kanban.highlights")

---@class kanban.TaskList.Opts
---@field data {title: string}
---@field index number
---@field ctx kanban.Ctx

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
---@param conf kanban.Config
function M.new(opts, conf)
	local self = setmetatable({}, M)

	local list_win = Snacks.win({
		enter = false,
		show = false,
		on_win = function()
			local list = opts.ctx.lists[self.index]
			self:set_keymaps(opts.ctx)
			self:set_events(opts.ctx)

			local filled_space = 0
			local list_height = list.win:size().height - 1

			local task_hidden_start_index = 0

			for task_index, task in ipairs(list.tasks) do
				-- calcuate available space for list
				local task_win = task:setup_win(list, opts.ctx)
				filled_space = filled_space + task_win:size().height - 1
				local is_list_space_full = filled_space >= list_height

				if is_list_space_full and task_hidden_start_index == 0 then
					task_hidden_start_index = task_index
				end

				task:init(opts.ctx, list, {
					task_win = task_win,
					visible_index = not is_list_space_full and task_index or nil,
				})
			end

			-- Set footer
			if task_hidden_start_index ~= 0 then
				self:update_scroll_info(0, #list.tasks + 1 - task_hidden_start_index)
			end
		end,
		title = opts.data.title,
		title_pos = "center",
		win = opts.ctx.root.win.win,
		height = 0.9,
		width = conf.list_min_width,
		row = 1,
		col = 10 + (conf.list_min_width + 3) * (opts.index - 1),
		relative = "win",
		border = "rounded",
		focusable = true,
		zindex = 15,
		wo = { winhighlight = hl.list },
		bo = {
			modifiable = false,
			filetype = "superkanban_list",
		},
	})

	self.win = list_win
	self.data = opts.data
	self.index = opts.index

	return self
end

---@param ctx kanban.Ctx
function M:init(ctx)
	self.win:show()
end

---@param ctx kanban.Ctx
function M:set_keymaps(ctx)
	local buf = self.win.buf
	local map = vim.keymap.set
	local act = self:get_actions(ctx)

	map("n", "q", act.close, { buffer = buf })

	map("n", "<C-l>", act.jump_horizontal(1), { buffer = buf })
	map("n", "<C-h>", act.jump_horizontal(-1), { buffer = buf })
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

function M:update_scroll_info(top, bottom)
	vim.api.nvim_win_set_config(self.win.win, {
		footer = string.format("↑%d-↓%d", top, bottom),
		footer_pos = "center",
	})
end

---A hack to Combine list and tasks in a type safe way
---@param list table
---@param tasks kanban.TaskUI
---@return kanban.TaskList.Ctx
function M.gen_list_ctx(list, tasks)
	list.tasks = tasks
	return list
end

---@param ctx kanban.Ctx
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
			ctx.root:exit(ctx)
		end,

		jump_horizontal = function(direction)
			if direction == nil then
				direction = 1
			end
			return function()
				local target_list = ctx.lists[self.index + direction]
				if not target_list then
					return
				end
				if #target_list.tasks == 0 then
					target_list.win:focus()
				end

				-- -- Updating index
				local target_index = 1
				if target_list.tasks[target_index] then
					target_list.tasks[target_index]:focus()
				end
			end
		end,
	}

	return act
end

return M
