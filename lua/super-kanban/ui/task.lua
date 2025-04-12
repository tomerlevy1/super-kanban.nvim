local hl = require("super-kanban.highlights")

---@class kanban.Task.Opts
---@field data kanban.TaskData
---@field index number
---@field list_index number
---@field list_win snacks.win
---@field root kanban.RootUI

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

	local task_win = Snacks.win({
		show = false,
		enter = false,
		text = function()
			return {
				opts.data.title or nil,
				#opts.data.tag > 0 and table.concat(opts.data.tag, " ") or nil,
				#opts.data.due > 0 and table.concat(opts.data.due, " ") or nil,
			}
		end,
		win = opts.list_win.win,
		width = 0,
		height = 4,
		col = 0,
		row = calculate_row_pos(opts.index),
		relative = "win",
		-- border = "rounded",
		border = { "", "", "", " ", "▁", "▁", "▁", " " },
		focusable = true,
		zindex = 20,
		wo = {
			winbar = "%=+",
			winhighlight = hl.task,
		},
		bo = {
			modifiable = true,
			filetype = "superkanban_task",
		},
	})

	self.win = task_win
	self.data = opts.data
	self.index = opts.index
	self.list_index = opts.list_index
	self.config = conf

	return self
end

function M:update_index_position()
	self.win.opts.row = calculate_row_pos(self.index)
	self.win:update()
end

function M:focus()
	self.win:focus()
	vim.wo.winhighlight = hl.taskActive
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
	local act = {
		swap_vertical = function(direction)
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
				self.index = moveto_index
				list.tasks[cur_index].index = moveto_index
				list.tasks[moveto_index].index = cur_index

				-- swap task in ctx
				list.tasks[moveto_index], list.tasks[cur_index] = list.tasks[cur_index], list.tasks[moveto_index]

				list.tasks[cur_index]:update_index_position() -- this is now the moveto item because ctx updated before
				self:update_index_position()
				self:focus()
			end
		end,
		swap_horizontal = function(direction)
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
				-- Updating opts
				self.win.opts.win = next_list.win.win
				-- swap task in ctx
				table.remove(prev_list.tasks, prev_index)
				table.insert(next_list.tasks, new_index, self)

				self:update_index_position()

				for index, tk in ipairs(prev_list.tasks) do
					tk.index = index
					tk:update_index_position()
				end
				self:focus()
			end
		end,
		jump_verticaly = function(direction)
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
					target_list.tasks[target_index]:focus()
				end
			end
		end,
		jump_horizontal = function(direction)
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

				-- Updating index
				local target_index = self.index
				if #target_list.tasks >= target_index then
					target_list.tasks[target_index]:focus()
				elseif target_list.tasks[#target_list.tasks] then
					target_list.tasks[#target_list.tasks]:focus()
				end
			end
		end,

		close = function()
			ctx.root:exit(ctx)
		end,
		create = function()
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
				root = ctx.root,
			}, self.config):init(ctx)
			list.tasks[target_index] = task

			task:focus()
			vim.cmd.startinsert()
		end,
	}

	return act
end

---@param ctx kanban.Ctx
function M:init(ctx)
	self.win:show()
	self:set_keymaps(ctx)
	self:set_events(ctx)

	return self
end

---@param ctx kanban.Ctx
function M:set_keymaps(ctx)
	local buf = self.win.buf
	local map = vim.keymap.set
	local act = self:get_actions(ctx)

	map("n", "q", act.close, { buffer = buf })
	map("n", "gn", act.create, { buffer = buf })

	map("n", "K", act.swap_vertical(-1), { buffer = buf })
	map("n", "J", act.swap_vertical(), { buffer = buf })

	map("n", "L", act.swap_horizontal(1), { buffer = buf })
	map("n", "H", act.swap_horizontal(-1), { buffer = buf })

	map("n", "<C-l>", act.jump_horizontal(1), { buffer = buf })
	map("n", "<C-h>", act.jump_horizontal(-1), { buffer = buf })
	map("n", "<C-k>", act.jump_verticaly(-1), { buffer = buf })
	map("n", "<C-j>", act.jump_verticaly(1), { buffer = buf })
end

---@param ctx kanban.Ctx
function M:set_events(ctx)
	self.win:on("BufEnter", function()
		vim.wo.winhighlight = hl.taskActive
	end, { buf = true })

	self.win:on("BufLeave", function()
		vim.wo.winhighlight = hl.task
	end, { buf = true })

	self.win:on({ "TextChanged", "TextChangedI", "TextChangedP" }, function()
		self:save(ctx)
	end, { buf = true })
end

return M
