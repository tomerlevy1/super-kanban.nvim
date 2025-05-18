local hl = require("super-kanban.highlights")

---@class superkanban.TaskList.Opts
---@field data {title: string}
---@field index number
---@field ctx superkanban.Ctx

---@class superkanban.TaskListUI
---@field data {title: string}
---@field index number
---@field win snacks.win
---@field ctx superkanban.Ctx
---@field type "list"
---@field scroll_info {top:number,bot:number}
---@overload fun(opts:superkanban.TaskList.Opts,config:{}): superkanban.TaskListUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M
---@type superkanban.Config
local config

---@param opts superkanban.TaskList.Opts
---@param conf superkanban.Config
function M.new(opts, conf)
	local self = setmetatable({}, M)

	local list_win = Snacks.win({
		enter = false,
		show = false,
		on_win = function()
			local list = opts.ctx.lists[self.index]
			self:set_keymaps(opts.ctx)
			self:set_events(opts.ctx)

			local task_can_fit = self:task_can_fit()
			local first_hidden_task_index = 0

			for index, task in ipairs(list.tasks) do
				-- calcuate available space for list
				local task_win = task:setup_win(list)
				local space_available = task_can_fit >= index

				if not space_available and first_hidden_task_index == 0 then
					first_hidden_task_index = index
				end

				task:mount(list, {
					task_win = task_win,
					visible_index = space_available and index or nil,
				})
			end

			-- Set footer
			self:update_scroll_info(0, first_hidden_task_index > 0 and #list.tasks + 1 - first_hidden_task_index or 0)
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
		keys = { q = false },
		wo = { winhighlight = hl.list },
		bo = {
			modifiable = false,
			filetype = "superkanban_list",
		},
	})

	self.ctx = opts.ctx
	self.win = list_win
	self.data = opts.data
	self.index = opts.index
	self.scroll_info = { top = 0, bot = 0 }

	self.type = "list"
	config = conf

	return self
end

function M:mount()
	self.win:show()
end

function M:exit()
	self.win:close()
end

---@param ctx superkanban.Ctx
function M:set_keymaps(ctx)
	local buf = self.win.buf
	local map = vim.keymap.set
	local act = self:get_actions(ctx)

	map("n", "q", act.close, { buffer = buf })

	map("n", "<C-l>", act.jump_horizontal(1), { buffer = buf })
	map("n", "<C-h>", act.jump_horizontal(-1), { buffer = buf })
end

---@param ctx superkanban.Ctx
function M:set_events(ctx)
	self.win:on("WinClosed", function()
		for _, tk in ipairs(ctx.lists[self.index].tasks) do
			tk:exit()
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
	self.scroll_info.top = top > 0 and top or 0
	self.scroll_info.bot = bottom > 0 and bottom or 0

	vim.api.nvim_win_set_config(self.win.win, {
		footer = string.format("↑%d-↓%d", self.scroll_info.top, self.scroll_info.bot),
		footer_pos = "center",
	})
end

function M:focus()
	self.win:focus()
end

function M:task_can_fit()
	local list_height = self.win:size().height - 2
	return math.floor(list_height / 5)
end

---@param direction number
---@param cur_task_index? number
function M:scroll_task(direction, cur_task_index)
	local is_downward = direction == 1
	local list = self.ctx.lists[self.index]
	if #list.tasks == 0 then
		return
	end

	-- exit if top or bottom task already in view
	if is_downward and list.tasks[#list.tasks]:has_visual_index() then
		return false
	elseif not is_downward and list.tasks[1]:has_visual_index() then
		return false
	end

	local task_can_fit = list:task_can_fit()
	local new_task_index, new_task_visual_index = nil, nil
	local hide_task_index = nil

	for index, tk in ipairs(list.tasks) do
		if tk:has_visual_index() then
			tk:update_visible_position(tk.visible_index + (is_downward and -1 or 1))

			if is_downward and type(tk.visible_index) == "number" then
				new_task_index, new_task_visual_index = index + 1, tk.visible_index + 1
			elseif not is_downward and new_task_visual_index == nil then
				new_task_index, new_task_visual_index = index - 1, 1
				hide_task_index = new_task_index + task_can_fit
			end
		elseif is_downward and type(new_task_visual_index) == "number" then
			break
		end

		if not is_downward and index == hide_task_index then
			tk:update_visible_position(nil)
			break
		end
	end

	local new_task_in_view = list.tasks[new_task_index]
	if new_task_in_view then
		new_task_in_view:update_visible_position(new_task_visual_index)
	end

	if is_downward then
		local bot = #list.tasks - new_task_index
		local top = #list.tasks - (bot + task_can_fit)
		list:update_scroll_info(top, bot)
	elseif not is_downward then
		local top = new_task_index - 1
		local bot = #list.tasks - (top + task_can_fit)
		list:update_scroll_info(top, bot)
	end

	return true
end

function M:bottom()
	local list = self.ctx.lists[self.index]
	if not list then
		return
	end
	if #list.tasks == 0 then
		return
	end

	if not list.tasks[#list.tasks]:closed() then
		list.tasks[#list.tasks]:focus()
		-- list:update_scroll_info(0, 0)
		return
	end

	local task_can_fit = self:task_can_fit()
	if #list.tasks < task_can_fit then
		task_can_fit = #list.tasks
	end

	for index = #list.tasks, 1, -1 do
		local tk = list.tasks[index]
		if task_can_fit > 0 then
			tk:update_visible_position(task_can_fit)
			task_can_fit = task_can_fit - 1
		else
			tk:update_visible_position(nil)
		end
	end

	list.tasks[#list.tasks]:focus()

	local bot = 0
	local top = #list.tasks - self:task_can_fit()
	list:update_scroll_info(top, bot)
end

function M:top()
	local list = self.ctx.lists[self.index]
	if not list then
		return
	end
	if #list.tasks == 0 then
		return
	end

	local task_can_fit = self:task_can_fit()

	if list.tasks[1]:has_visual_index() then
		list.tasks[1]:focus()
		-- list:update_scroll_info(0, 0)
		return
	end

	for index = 1, #list.tasks, 1 do
		local tk = list.tasks[index]
		if task_can_fit >= index then
			-- dd(tk.data.title)
			tk:update_visible_position(index)
		else
			tk:update_visible_position(nil)
		end
	end

	list.tasks[1]:focus()

	local top = 0
	local bot = #list.tasks - task_can_fit
	list:update_scroll_info(top, bot)
end

---A hack to Combine list and tasks in a type safe way
---@param list table
---@param tasks superkanban.TaskUI
---@return superkanban.TaskList.Ctx
function M.gen_list_ctx(list, tasks)
	list.tasks = tasks
	return list
end

---@param ctx superkanban.Ctx
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
			ctx.root:exit()
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
					target_list:focus()
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
