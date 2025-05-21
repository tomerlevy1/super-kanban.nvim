local hl = require("super-kanban.highlights")
local utils = require("super-kanban.utils")

---@class superkanban.Task.Opts
---@field data superkanban.TaskData
---@field index number
---@field list_index number
---@field ctx superkanban.Ctx

---@class superkanban.TaskUI
---@field data superkanban.TaskData
---@field index number
---@field visible_index number
---@field win snacks.win
---@field list_index number
---@field ctx superkanban.Ctx
---@field config superkanban.Config
---@field type "task"
---@overload fun(opts:superkanban.Task.Opts,config :{}): superkanban.TaskUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M
---@type superkanban.Config
local config

local task_height = 4

local function extract_tags(text)
	local tags = {}
	for tag in text:gmatch("#%w+") do
		table.insert(tags, tag)
	end
	return tags
end

local function extract_dates(text)
	local dates = {}
	for date in text:gmatch("(@{%d+[,-/]%d%d?[,-/]%d%d?})") do
		table.insert(dates, date)
	end
	return dates
end

local function calculate_row_pos(index)
	return (task_height + 1) * (index - 1)
end

---@param opts superkanban.Task.Opts
---@param conf superkanban.Config
function M.new(opts, conf)
	local self = setmetatable({}, M)
	config = conf

	self.data = opts.data
	self.index = opts.index
	self.ctx = opts.ctx
	self.list_index = opts.list_index

	self.type = "task"

	return self
end

---@param list superkanban.TaskListUI
---@return snacks.win
function M:setup_win(list)
	self.win = Snacks.win({
		show = false,
		enter = false,
		on_win = function()
			self:set_events()
			self:set_keymaps()
		end,
		text = function()
			return utils.get_lines_from_task(self.data)
		end,
		relative = "win",
		win = list.win.win,
		width = 0,
		height = task_height,
		col = 0,
		row = calculate_row_pos(self.index),
		border = { "", "", "", " ", "▁", "▁", "▁", " " },
		focusable = true,
		zindex = 20,
		keys = { q = false },
		wo = {
			winbar = self:generate_winbar(),
			winhighlight = hl.task,
			wrap = true,
		},
		bo = { modifiable = true, filetype = "superkanban_task" },
	})

	return self.win
end

---@param list superkanban.TaskListUI
---@param opts? {task_win?:snacks.win,visible_index?:number}
function M:mount(list, opts)
	opts = opts or {}

	local task_win = opts.task_win
	if not task_win then
		task_win = self:setup_win(list)
	end

	if type(opts.visible_index) == "number" then
		self.visible_index = opts.visible_index
		task_win:show()
	end

	return self
end

function M:focus()
	if self:closed() then
		self.win:show()
	end

	self.win:focus()
	vim.api.nvim_set_option_value("winhighlight", hl.taskActive, { win = self.win.win })
end

function M:exit()
	self.win:close()
  self.visible_index = nil
end

function M:closed()
	return self.win.closed ~= false
end

function M:has_visual_index()
	return type(self.visible_index) == "number" and self.visible_index > 0
end

function M:in_view()
	return self:has_visual_index() and not self:closed()
end

function M:generate_winbar()
	local f_str = "%%=%s"
	return f_str:format(self:get_relative_date())
end

function M:update_winbar()
	local ft = vim.api.nvim_get_option_value("filetype", { buf = self.win.buf })

	if ft == "superkanban_task" then
		vim.api.nvim_set_option_value("winbar", self:generate_winbar(), { win = self.win.win })
	end
end

function M:get_relative_date()
	if #self.data.due == 0 then
		return ""
	end
	local date_str = self.data.due[1]
	if not date_str then
		return ""
	end
	local ok, result = pcall(utils.get_relative_time, utils.extract_date(date_str))

	if ok then
		return result
	end

	return ""
end

---@param new_index? number
function M:update_visible_position(new_index)
	if type(new_index) == "number" and new_index > 0 then
		self.win.opts.row = calculate_row_pos(new_index)

		if self:closed() then
			self.win:show()
		end

		self.visible_index = new_index
		self.win:update()
		self:update_winbar()
	else
		self.win:hide()
		self.visible_index = nil
	end
end

---@param should_focus? boolean
function M:delete_task(should_focus)
	local list = self.ctx.lists[self.list_index]
	local target_index = self.index

	-- Remove task
	self:exit()
	table.remove(list.tasks, target_index)

	list:fill_empty_space({ from = target_index - 1, to = target_index })

	-- focus on task or list
	if should_focus ~= false then
		local focus_target = list.tasks[target_index] or list.tasks[target_index - 1] or list
		focus_target:focus()
	end
end

function M:extract_buffer()
	local lines = self.win:lines()

	local title = lines[1]
	local tags = {}
	local dates = {}

	for i = 2, #lines, 1 do
		local found_tags = extract_tags(lines[i])
		if #found_tags >= 1 then
			vim.list_extend(tags, found_tags)
		end

		local found_dates = extract_dates(lines[i])
		if #found_dates >= 1 then
			vim.list_extend(dates, found_dates)
		end
	end

	self.data.title = title
	self.data.tag = tags
	self.data.due = dates
end

function M:get_actions()
	local ctx = self.ctx
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

			if
				(#list.tasks == 1)
				or (direction == 1 and self.index == #list.tasks)
				or (direction == -1 and self.index == 1)
			then
				return
			end

			-- Update index
			local cur_index = self.index
			local target_index = self.index + direction
			local cur_task = list.tasks[cur_index]
			local target_task = list.tasks[target_index]

			if target_task:closed() then
				list:scroll_task(direction)
			end

			-- swap index
			local cur_v_index, target_v_index = target_task.visible_index, cur_task.visible_index
			cur_task.index, target_task.index = target_index, cur_index
			-- swap task in ctx
			list.tasks[target_index], list.tasks[cur_index] = cur_task, target_task

			cur_task:update_visible_position(cur_v_index)
			target_task:update_visible_position(target_v_index)
			cur_task:focus()
		end
	end

	actions.swap_horizontal = function(direction)
		if direction == nil then
			direction = 1
		end
		return function()
			local target_list = ctx.lists[self.list_index + direction]
			if not target_list then
				return
			end

			if not target_list:has_visual_index() or target_list:closed() then
				self.ctx.board:scroll_list(direction, self.list_index)
			end

			self:delete_task(false)

			-- Update task+list index and parent win
			local target_index = #target_list.tasks + 1
			local new_task = self.new({
				data = self.data,
				index = target_index,
				ctx = self.ctx,
			}, config):mount(target_list)
			target_list.tasks[target_index] = new_task
			target_list:bottom()
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
			local target_list = ctx.lists[self.list_index + direction]
			if not target_list then
				return
			end

			if not target_list:has_visual_index() or target_list:closed() then
				self.ctx.board:scroll_list(direction, self.list_index)
			end

			if #target_list.tasks == 0 then
				target_list:focus()
			end

			-- Focus same visual_index task
			if #target_list.tasks >= self.visible_index then
				local target_task = target_list:find_a_visible_task(self.visible_index)
				if target_task then
					target_task:focus()
				end
			elseif target_list.tasks[#target_list.tasks] then
				target_list.tasks[#target_list.tasks]:focus()
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
		ctx.board:exit()
	end
	actions.create = function()
		ctx.lists[self.list_index]:create_task()
	end
	actions.delete = function()
		self:delete_task()
	end

	return actions
end

function M:set_keymaps()
	local buf = self.win.buf
	local map = vim.keymap.set
	local act = self:get_actions()

	map("n", "q", act.close, { buffer = buf })
	map("n", "gn", act.create, { buffer = buf })
	map("n", "gD", act.delete, { buffer = buf })

	map("n", "x", act.info, { buffer = buf })

	map("n", "<A-k>", act.swap_vertical(-1), { buffer = buf })
	map("n", "<A-j>", act.swap_vertical(1), { buffer = buf })
	map("n", "<A-l>", act.swap_horizontal(1), { buffer = buf })
	map("n", "<A-h>", act.swap_horizontal(-1), { buffer = buf })

	map("n", "gg", act.top, { buffer = buf })
	map("n", "G", act.bottom, { buffer = buf })

	map("n", "/", function()
		self.ctx.board:search(self)
	end, { buffer = buf, nowait = true })

	map("n", "<C-n>", function()
		self.ctx.board:scroll_list(1, self.index)
	end, { buffer = buf })
	map("n", "<C-p>", function()
		self.ctx.board:scroll_list(-1, self.index)
	end, { buffer = buf })

	map("n", "zn", function()
		self.ctx.board:create_list()
	end, { buffer = buf })
	map("n", "zD", function()
		self.ctx.lists[self.list_index]:delete_list()
	end, { buffer = buf })
	map("n", "z0", function()
		self.ctx.board:scroll_to_top()
	end, { buffer = buf })
	map("n", "z$", function()
		self.ctx.board:scroll_to_bottom()
	end, { buffer = buf })

	map("n", "<C-l>", act.jump_horizontal(1), { buffer = buf })
	map("n", "<C-h>", act.jump_horizontal(-1), { buffer = buf })
	map("n", "<C-k>", act.jump_verticaly(-1), { buffer = buf })
	map("n", "<C-j>", act.jump_verticaly(1), { buffer = buf })
	map("n", "<S-tab>", act.jump_verticaly(-1), { buffer = buf })
	map("n", "<tab>", act.jump_verticaly(1), { buffer = buf })
end

function M:set_events()
	self.win:on({ "BufEnter", "WinEnter" }, function()
		vim.api.nvim_set_option_value("winhighlight", hl.taskActive, { win = self.win.win })
	end, { buf = true })

	self.win:on({ "BufLeave", "WinLeave" }, function()
		vim.api.nvim_set_option_value("winhighlight", hl.task, { win = self.win.win })
	end, { buf = true })

	self.win:on({ "TextChanged", "TextChangedI", "TextChangedP" }, function()
		self:extract_buffer()
		self:update_winbar()
	end, { buf = true })
end

return M
