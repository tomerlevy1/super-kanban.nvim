local hl = require("super-kanban.highlights")

---@class kanban.Task.Opts
---@field data kanban.TaskData
---@field index number
---@field list_index number
---@field visible_index number|nil
---@field list_win snacks.win
---@field ctx kanban.Ctx

---@class kanban.TaskUI
---@field data kanban.TaskData
---@field index number
---@field win snacks.win
---@field list_index number
---@field config kanban.Config
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
			return {
				self.data.title or nil,
				#self.data.tag > 0 and table.concat(self.data.tag, " ") or nil,
				#self.data.due > 0 and table.concat(self.data.due, " ") or nil,
			}
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

function M:update_index_position()
	self.win.opts.row = calculate_row_pos(self.index)
	self.win:update()
end

function M:closed()
	return self.win.closed ~= false
end

function M:update_visible_position()
	if type(self.visible_index) == "number" and self.visible_index > 0 then
		self.win.opts.row = calculate_row_pos(self.visible_index)
		self.win:update()
		if self:closed() then
			self.win:show()
		end
	else
		self.win:hide()
		-- dd("hidding ", self.data.title, self.win.closed)
	end
end

---@param from_location? number[]
---@param only_move_into_view? boolean
function M:focus(from_location, only_move_into_view)
	if self:closed() then
		if not from_location then
			return
		end

		local direction = self.index > from_location[2] and 1 or -1
		local is_downward = direction == 1

		local list = self.ctx.lists[self.list_index]
		local tasks = list.tasks

		local list_height = list.win:size().height - 2
		local task_can_fit = math.floor(list_height / 5)
		if #tasks < task_can_fit then
			task_can_fit = #tasks
		end

		-- Set loop incremental or decremental
		local loop_step = is_downward and -1 or 1
		local visual_index = is_downward and task_can_fit or 1

		for cur_index = self.index, (is_downward and 1 or self.index + task_can_fit), loop_step do
			local cur_task = tasks[cur_index]

			if (is_downward and visual_index <= 0) or visual_index > task_can_fit then
				cur_task.visible_index = nil
				cur_task:update_visible_position()
			else
				cur_task.visible_index = visual_index
				cur_task:update_visible_position()
				if self:closed() then
					cur_task.win:show()
				end
			end

			visual_index = visual_index + loop_step
		end
	end

	if not only_move_into_view then
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
				moveto_task:focus({ cur_task.list_index, cur_task.index }, true)
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
			local target_list = ctx.lists[self.list_index]
			if not target_list then
				return
			end
			if #target_list.tasks == 0 then
				return
			end

			-- Updating index
			local target_index = self.index + direction
			if target_list.tasks[target_index] then
				local found_task = target_list.tasks[target_index]
				found_task:focus({ self.list_index, self.index })
			end
		end
	end
	actions.jump_top = function()
    -- FIXME: fix top & bottom jumps
		local target_list = ctx.lists[self.list_index]
		if not target_list then
			return
		end
		if #target_list.tasks == 0 then
			return
		end
		target_list.tasks[1]:focus({ self.list_index, self.index })
	end
	actions.jump_bottom = function()
		local target_list = ctx.lists[self.list_index]
		if not target_list then
			return
		end
		if #target_list.tasks == 0 then
			return
		end
		target_list.tasks[#target_list.tasks]:focus({ self.list_index, self.index })
	end

	actions.jump_horizontal = function(direction)
		if direction == nil then
			direction = 1
		end
		return function()
			local target_list = ctx.lists[self.list_index + direction]
			if not target_list then
				return
			end
			if #target_list.tasks == 0 then
				target_list.win:focus()
			end

			-- Focus same visual_index task
			local target_index = self.index
			if #target_list.tasks >= target_index then
				for index = target_index, #target_list.tasks, 1 do
					local tk = target_list.tasks[index]
					if tk.visible_index == self.visible_index then
						tk:focus()
						break
					end
				end
			elseif target_list.tasks[#target_list.tasks] then
				target_list.tasks[#target_list.tasks]:focus()
			end
		end
	end

	actions.info = function()
		dd(self.data.title, string.format("index %s, visual_index %s", self.index, self.visible_index))
	end

	actions.close = function()
		ctx.root:exit(ctx)
	end
	actions.create = function()
		local list = ctx.lists[self.list_index]
		local target_index = #list.tasks + 1
		local task = self.new({
			data = {
				title = "",
				check = " ",
				tag = {},
				due = {},
			},
			index = target_index,
			list_index = self.list_index,
			list_win = list.win,
			ctx = ctx,
		}, self.config):init(ctx, list)
		list.tasks[target_index] = task

		task:focus({ self.list_index, self.index })
		vim.cmd.startinsert()
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

	map("n", "x", act.info, { buffer = buf })

	map("n", "<A-k>", act.swap_vertical(-1), { buffer = buf })
	map("n", "<A-j>", act.swap_vertical(), { buffer = buf })
	map("n", "<A-l>", act.swap_horizontal(1), { buffer = buf })
	map("n", "<A-h>", act.swap_horizontal(-1), { buffer = buf })

	map("n", "gg", act.jump_top, { buffer = buf })
	map("n", "G", act.jump_bottom, { buffer = buf })

	map("n", "<C-l>", act.jump_horizontal(1), { buffer = buf })
	map("n", "<C-h>", act.jump_horizontal(-1), { buffer = buf })
	map("n", "<C-k>", act.jump_verticaly(-1), { buffer = buf })
	map("n", "<C-j>", act.jump_verticaly(1), { buffer = buf })
end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on("BufEnter", function()
		vim.api.nvim_set_option_value("winhighlight", hl.taskActive, { win = self.win.win })
	end, { buf = true })

	self.win:on("BufLeave", function()
		vim.api.nvim_set_option_value("winhighlight", hl.task, { win = self.win.win })
	end, { buf = true })

	self.win:on({ "TextChanged", "TextChangedI", "TextChangedP" }, function()
		self:save(ctx)
	end, { buf = true })
end

return M
