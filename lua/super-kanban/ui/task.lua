local hl = require("super-kanban.highlights")

---@class kanban.Task.Opts
---@field data kanban.TaskData
---@field index number
---@field list_index number
---@field list_win snacks.win

---@class kanban.TaskUI
---@field data kanban.TaskData
---@field index number
---@field win snacks.win
---@field list_index number
---@field config kanban.Config
---@field type "task"
---@overload fun(opts:kanban.Task.Opts,config :{}): kanban.TaskUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

local function calculate_row_pos(index)
	return (4 + 1) * (index - 1)
end

---@param opts kanban.Task.Opts
---@param conf kanban.Config
function M.new(opts, conf)
	local self = setmetatable({}, M)

	self.data = opts.data
	self.index = opts.index
	self.list_index = opts.list_index
	self.config = conf
	self.type = "task"

	return self
end

---@param list kanban.TaskListUI
---@param ctx kanban.Ctx
---@return snacks.win
function M:setup_win(list, ctx)
	local task_win = Snacks.win({
		show = false,
		enter = false,
		on_win = function()
			self:set_events(ctx)
			self:set_keymaps(ctx)
		end,
		text = function()
			return self:render_lines()
		end,
		win = list.win.win,
		width = 0,
		height = 4,
		col = 0,
		row = calculate_row_pos(self.index),
		relative = "win",
		-- border = "rounded",
		border = { "", "", "", " ", "▁", "▁", "▁", " " },
		focusable = true,
		zindex = 20,
		keys = { q = false },
		wo = {
			winbar = "%=+",
			winhighlight = hl.task,
			wrap = true,
		},
		bo = {
			modifiable = true,
			filetype = "superkanban_task",
		},
	})

	self.win = task_win
	self.ctx = ctx
	return task_win
end

function M:render_lines()
	local lines = {
		self.data.title or "",
	}

	if #self.data.tag > 0 then
		lines[2] = table.concat(self.data.tag, " ")
	end

	if #self.data.due > 0 then
		if lines[2] then
			lines[2] = lines[2] .. " " .. table.concat(self.data.due, " ")
		else
			lines[2] = table.concat(self.data.due, " ")
		end
	end
	return lines
end

function M:update_index_position()
	self.win.opts.row = calculate_row_pos(self.index)
	self.win:update()
end

function M:closed()
	return self.win.closed ~= false
end

function M:has_visual_index()
	return type(self.visible_index) == "number" and self.visible_index > 0
end

function M:update_visible_position(new_index)
	if type(new_index) == "number" and new_index > 0 then
		self.win.opts.row = calculate_row_pos(new_index)

		if self:closed() then
			self.win:show()
		end

		self.visible_index = new_index
		self.win:update()
	else
		self.win:hide()
		self.visible_index = nil
	end
end

---@param from_location? number[]
---@param opts? {only_move_into_view?:boolean}
function M:focus(from_location, opts)
	opts = opts or {}

	if self:closed() then
		if not from_location then
			return
		end

		local direction = self.index > from_location[2] and 1 or -1
		local is_downward = direction == 1
		local jump_difference = is_downward and self.index - from_location[2] or from_location[2] - self.index

		local list = self.ctx.lists[self.list_index]
		local tasks = list.tasks

		local list_height = list.win:size().height - 2
		local task_can_fit = math.floor(list_height / 5)
		if #tasks < task_can_fit then
			task_can_fit = #tasks
		end

		-- Set loop incremental or decremental
		local loop_step = is_downward and -1 or 1
		local loop_ending = is_downward and 1 or jump_difference == 1 and self.index + task_can_fit or #tasks
		local visual_index = is_downward and task_can_fit or 1

		for cur_index = self.index, loop_ending, loop_step do
			local cur_task = tasks[cur_index]

			if (is_downward and visual_index <= 0) or visual_index > task_can_fit then
				cur_task:update_visible_position(nil)
			else
				cur_task:update_visible_position(visual_index)
				if self:closed() then
					cur_task.win:show()
				end
			end

			visual_index = visual_index + loop_step
		end

		local info = { top = 0, bottom = 0 }
		-- if #tasks <= task_can_fit then
		-- 	dd("zero")
		if is_downward then
			local bot = #tasks - self.index
			local top = #tasks - (bot + task_can_fit)
			info.top = top
			info.bottom = bot
		elseif not is_downward then
			local top = self.index - 1
			local bot = #tasks - (top + task_can_fit)
			info.top = top
			info.bottom = bot
		end

		list:update_scroll_info(info.top, info.bottom)
	end

	if not opts.only_move_into_view then
		if self:closed() then
			self.win:show()
		end
		self.win:focus()
		vim.api.nvim_set_option_value("winhighlight", hl.taskActive, { win = self.win.win })
	end
end

local function parse_tags(text)
	local tags = {}
	for tag in text:gmatch("#%w+") do
		table.insert(tags, tag)
	end
	return tags
end

local function parse_dates(text)
	local dates = {}
	for date in text:gmatch("(@%d%d%d%d/%d?%d/%d?%d)") do
		table.insert(dates, date)
	end
	return dates
end

---@param ctx kanban.Ctx
function M:save(ctx)
	local lines = self.win:lines()

	local title = lines[1]
	local tags = {}
	local dates = {}

	for i = 2, #lines, 1 do
		local found_tags = parse_tags(lines[i])
		if #found_tags >= 1 then
			vim.list_extend(tags, found_tags)
		end

		local found_dates = parse_dates(lines[i])
		if #found_dates >= 1 then
			vim.list_extend(dates, found_dates)
		end
	end

	self.data.title = title
	self.data.tag = tags
	self.data.due = dates
end

---@param ctx kanban.Ctx
function M:get_actions(ctx)
	local actions = {}

	-- FIXME: update swap actions
	actions.swap_vertical = function(direction)
		if direction == nil then
			direction = 1
		end
		return function()
			local list = ctx.lists[self.list_index]
			if not list then
				return
			end

			if (direction == 1 and self.index == #list.tasks) or (direction == -1 and self.index == 1) then
				return
			end

			-- Update index
			local cur_index = self.index
			local moveto_index = self.index + direction
			local cur_task = list.tasks[cur_index]
			local moveto_task = list.tasks[moveto_index]

			if moveto_task:closed() then
				moveto_task:focus({ cur_task.list_index, cur_task.index }, { only_move_into_view = true })
			end

			cur_task.index, moveto_task.index = moveto_index, cur_index
			cur_task.visible_index, moveto_task.visible_index = moveto_task.visible_index, cur_task.visible_index

			-- swap task in ctx
			list.tasks[moveto_index], list.tasks[cur_index] = cur_task, moveto_task

			moveto_task:update_visible_position()
			cur_task:update_visible_position()
			cur_task:focus()
		end
	end

	actions.swap_horizontal = function(direction)
		if direction == nil then
			direction = 1
		end
		return function()
			local prev_list = ctx.lists[self.list_index]
			local next_list = ctx.lists[self.list_index + direction]
			if not next_list then
				return
			end

			-- Updating index
			local prev_index = self.index
			local new_index = #next_list.tasks + 1
			self.index = new_index
			self.list_index = next_list.index
			-- Updating the relative parent
			self.win.opts.win = next_list.win.win
			-- swap task in ctx
			table.remove(prev_list.tasks, prev_index)
			table.insert(next_list.tasks, new_index, self)

			self.win:hide()
			if #next_list.tasks > 1 then
				self:focus({ next_list.index, next_list.tasks[new_index - 1].index })
			else
				self.visible_index = 1
				self:update_visible_position()
				self:focus()
			end

			-- Update prev_list task positions
			local found_new_task_will_be_in_view = nil
			for cur_index = prev_index, #prev_list.tasks, 1 do
				local tk = prev_list.tasks[cur_index]
				tk.index = tk.index - 1

				if type(tk.visible_index) == "number" then
					tk.visible_index = tk.visible_index - 1
					tk:update_visible_position()
				elseif found_new_task_will_be_in_view == nil then
					found_new_task_will_be_in_view = true
					tk.visible_index = prev_list.tasks[cur_index - 1].visible_index + 1
					tk:update_visible_position()
				end
			end
		end
	end

	---@param direction? number
	actions.jump_verticaly = function(direction)
		if direction == nil then
			direction = 1
		end
		return function()
			local list = ctx.lists[self.list_index]
			if not list then
				return
			end
			if #list.tasks == 0 then
				return
			end

			local target_task = list.tasks[self.index + direction]
			if target_task and target_task:has_visual_index() then
				target_task:focus()
			elseif target_task and not target_task:has_visual_index() then
				list:scroll_task(direction, self.index)
				target_task:focus()
			end
		end
	end

	---@param direction? number
	actions.jump_horizontal = function(direction)
		if direction == nil then
			direction = 1
		end
		return function()
			local list = ctx.lists[self.list_index + direction]
			if not list then
				return
			end
			if #list.tasks == 0 then
				list:focus()
			end

			-- Focus same visual_index task
			local target_index = self.visible_index
			if #list.tasks >= target_index then
				for index = target_index, #list.tasks, 1 do
					local tk = list.tasks[index]
					if tk.visible_index == self.visible_index then
						tk:focus()
						break
					end
				end
			elseif list.tasks[#list.tasks] then
				list.tasks[#list.tasks]:focus()
			end
		end
	end

	actions.top = function()
		local list = ctx.lists[self.list_index]
		if not list then
			return
		end
		list:top()
	end

	actions.bottom = function()
		local list = ctx.lists[self.list_index]
		if not list then
			return
		end
		list:bottom()
	end

	actions.info = function()
		dd(self.data.title, string.format("index %s, visual_index %s", self.index, self.visible_index))

		local list = ctx.lists[self.list_index]
		for _, tk in ipairs(list.tasks) do
			log(tk.data.title, string.format("index %s, visual_index %s", tk.index, tk.visible_index))
		end
	end

	actions.close = function()
		ctx.root:exit(ctx)
	end
	actions.create = function()
		local list = ctx.lists[self.list_index]
		local target_index = #list.tasks + 1

		local task_can_fit = list:task_can_fit()
		local list_space_available = #list.tasks < task_can_fit

		local new_task = self.new({
			data = {
				title = "",
				check = " ",
				tag = {},
				due = {},
			},
			index = target_index,
			list_index = self.list_index,
			list_win = list.win,
		}, self.config):init(ctx, list, { visible_index = list_space_available and #list.tasks + 1 or nil })
		list.tasks[target_index] = new_task

		list:bottom()
		vim.cmd.startinsert()
	end

	actions.delete = function()
		local list = ctx.lists[self.list_index]
		local target_index = self.index

		-- Select next or prev task
		local focus_task = list.tasks[target_index + 1] or list.tasks[target_index - 1]

		-- Remove task
		self.win:close()
		table.remove(list.tasks, target_index)

		-- Update current list task position & index
		local found_task_will_be_in_view_from_bottom = nil
		for cur_index = target_index, #list.tasks, 1 do
			local tk = list.tasks[cur_index]
			tk.index = cur_index

			if type(tk.visible_index) == "number" then
				tk:update_visible_position(tk.visible_index - 1)
			elseif found_task_will_be_in_view_from_bottom == nil then
				found_task_will_be_in_view_from_bottom = true
				tk:update_visible_position(list:task_can_fit())
				-- Update scroll info for bottom
				list:update_scroll_info(list.scroll_info.top, list.scroll_info.bot - 1)
			end
		end

		-- There is no hidden task in bottom so try to show new task from top.
		if found_task_will_be_in_view_from_bottom == nil then
			local scrolled = list:scroll_task(-1)
			if scrolled then
				focus_task = list.tasks[target_index - 1] or focus_task
			end
		end

		if focus_task and focus_task:has_visual_index() then
			focus_task:focus()
		elseif #list.tasks == 0 then
			list:focus()
		end
	end

	return actions
end

---@param ctx kanban.Ctx
---@param list kanban.TaskListUI
---@param opts? {task_win?:snacks.win,visible_index?:number}
function M:init(ctx, list, opts)
	opts = opts or {}

	local task_win = opts.task_win
	if not task_win then
		task_win = self:setup_win(list, ctx)
	end

	if type(opts.visible_index) == "number" then
		self.visible_index = opts.visible_index
		task_win:show()
	end
	return self
end

---@param ctx kanban.Ctx
function M:set_keymaps(ctx)
	local buf = self.win.buf
	local map = vim.keymap.set
	local act = self:get_actions(ctx)

	map("n", "q", act.close, { buffer = buf })
	map("n", "gn", act.create, { buffer = buf })
	map("n", "X", act.delete, { buffer = buf })

	map("n", "x", act.info, { buffer = buf })

	-- map("n", "<A-k>", act.swap_vertical(-1), { buffer = buf })
	-- map("n", "<A-j>", act.swap_vertical(), { buffer = buf })
	-- map("n", "<A-l>", act.swap_horizontal(1), { buffer = buf })
	-- map("n", "<A-h>", act.swap_horizontal(-1), { buffer = buf })

	map("n", "gg", act.top, { buffer = buf })
	map("n", "G", act.bottom, { buffer = buf })

	map("n", "<C-l>", act.jump_horizontal(1), { buffer = buf })
	map("n", "<C-h>", act.jump_horizontal(-1), { buffer = buf })
	map("n", "<C-k>", act.jump_verticaly(-1), { buffer = buf })
	map("n", "<C-j>", act.jump_verticaly(1), { buffer = buf })
	map("n", "<S-tab>", act.jump_verticaly(-1), { buffer = buf })
	map("n", "<tab>", act.jump_verticaly(1), { buffer = buf })
end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on({ "BufEnter", "WinEnter" }, function()
		vim.api.nvim_set_option_value("winhighlight", hl.taskActive, { win = self.win.win })
	end, { buf = true })

	self.win:on({ "BufLeave", "WinLeave" }, function()
		vim.api.nvim_set_option_value("winhighlight", hl.task, { win = self.win.win })
	end, { buf = true })

	self.win:on({ "TextChanged", "TextChangedI", "TextChangedP" }, function()
		self:save(ctx)
	end, { buf = true })
end

return M
