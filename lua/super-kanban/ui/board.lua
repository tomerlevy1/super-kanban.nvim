local hl = require("super-kanban.highlights")
local List = require("super-kanban.ui.list")

---@class superkanban.BoardUI
---@field win snacks.win
---@field ctx superkanban.Ctx
---@field type "board"
---@field scroll_info {first:number,last:number}
---@overload fun(config :{}): superkanban.BoardUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M
---@type superkanban.Config
local config

local function generate_winbar(title)
	return string.format(
		"%%#KanbanWinbar#%%= %%#KanbanFileTitleAlt#%%#KanbanFileTitle#%s%%#KanbanFileTitleAlt#%%#KanbanWinbar# %%=",
		title
	)
end

---@param conf superkanban.Config
function M.new(conf)
	local self = setmetatable({}, M)
	config = conf

	self.win = Snacks.win({
		zindex = 10,
		width = 0,
		height = vim.o.lines - 2,
		enter = false,
		focusable = true,
		col = 0,
		row = 0,
		border = { "", " ", "", "", "", "", "", "" },
		wo = { winhighlight = hl.board, winbar = generate_winbar("Kanban") },
		bo = { modifiable = false, filetype = "superkanban_board" },
	})

	self.type = "board"
	self.scroll_info = { first = 0, last = 0 }

	return self
end

---@param ctx superkanban.Ctx
function M:mount(ctx)
	self:set_keymaps()
	self:set_events()

	local list_can_fit = self:item_can_fit()
	local focus_item = nil
	local first_hidden_task_index = 0

	for index, list in ipairs(ctx.lists) do
		local space_available = list_can_fit >= index
		if focus_item == nil and space_available and #list.tasks > 0 then
			focus_item = list.tasks[1]
		end

		if not space_available and first_hidden_task_index == 0 then
			first_hidden_task_index = index
		end

		list:mount({ visible_index = space_available and index or nil })
	end

	if focus_item then
		focus_item:focus()
	elseif ctx.lists[1] then
		ctx.lists[1]:focus()
	end

	self:update_scroll_info(0, first_hidden_task_index > 0 and #ctx.lists + 1 - first_hidden_task_index or 0)

	self.ctx = ctx
end

function M:item_can_fit()
	local width = self.win:size().width - 2 - config.board.padding.left
	return math.floor(width / config.list_min_width)
end

function M:update_scroll_info(first, last)
	self.scroll_info.first = first > 0 and first or 0
	self.scroll_info.last = last > 0 and last or 0

	vim.api.nvim_win_set_config(self.win.win, {
		title = string.format("← %d | %d →  ", self.scroll_info.first, self.scroll_info.last),
		title_pos = "right",
	})
end

---@param opts {from:number,to:number}
function M:fill_empty_space(opts)
	local lists = self.ctx.lists

	local list_can_fit = self:item_can_fit()

	local empty_spaces = opts.to - opts.from
	local last_used_visible_index = 0

	for index = opts.to, #lists, 1 do
		local item = lists[index]
		item.index = item.index - 1

		if item:in_view() then
			last_used_visible_index = item.visible_index - 1
			item:update_visible_position(last_used_visible_index)
		elseif empty_spaces > 0 and last_used_visible_index < list_can_fit then
			last_used_visible_index = last_used_visible_index == 0 and list_can_fit or last_used_visible_index + 1
			item:update_visible_position(last_used_visible_index)

			-- Update scroll info for right side
			self:update_scroll_info(self.scroll_info.first, self.scroll_info.last - 1)
			empty_spaces = empty_spaces - 1
		end
	end

	while empty_spaces > 0 do
		self:scroll_board(-1, 0)
		empty_spaces = empty_spaces - 1
	end
end

function M:exit()
	self.win:close()
end

function M:on_exit()
	require("super-kanban.parser.markdown").write_file(self.ctx, config)
	for _, li in ipairs(self.ctx.lists) do
		li:exit()
	end
	self:exit()
end

function M:set_events()
	self.win:on("WinClosed", function()
		self:on_exit()
	end, { win = true })

	self.win:on("BufEnter", function()
		vim.defer_fn(function()
			self.win:destroy()
		end, 10)
	end, { buf = true })
end

function M:set_keymaps() end

function M:create_list()
	local lists = self.ctx.lists
	local target_index = #lists + 1

	local list_can_fit = self:item_can_fit()
	local space_available = #lists < list_can_fit

	local new_list = List({
		data = { title = "New List " .. target_index },
		index = target_index,
		ctx = self.ctx,
	}, config)

	local tasks = {}
	lists[target_index] = List.generate_list_ctx(new_list, tasks)
	new_list:mount({ visible_index = space_available and target_index or nil })

	-- TODO: add rename list ui
	self:jump_to_last_list()
	-- vim.cmd.startinsert()
end

---@param direction number
---@param cur_list_index? number
function M:scroll_board(direction, cur_list_index)
	local is_right = direction == 1

	if #self.ctx.lists == 0 then
		return false
	end
	local lists = self.ctx.lists

	-- exit if first or last item already in view
	if is_right and lists[#lists]:has_visual_index() then
		return false
	elseif not is_right and lists[1]:has_visual_index() then
		return false
	end

	local list_can_fit = self.ctx.board:item_can_fit()
	local new_item_index, new_item_visual_index = nil, nil
	local hide_task_index = nil

	for index, item in ipairs(lists) do
		if item:in_view() then
			item:update_visible_position(item.visible_index + (is_right and -1 or 1))

			if is_right and type(item.visible_index) == "number" then
				new_item_index, new_item_visual_index = index + 1, item.visible_index + 1
			elseif not is_right and new_item_visual_index == nil then
				new_item_index, new_item_visual_index = index - 1, 1
				hide_task_index = new_item_index + list_can_fit
			end
		elseif is_right and type(new_item_visual_index) == "number" then
			break
		end

		if not is_right and index == hide_task_index then
			item:update_visible_position(nil)
			break
		end
	end

	local new_task_in_view = lists[new_item_index]
	if new_task_in_view then
		new_task_in_view:update_visible_position(new_item_visual_index)
	end

	-- update scroll info
	if is_right then
		local bot = #lists - new_item_index
		local top = #lists - (bot + list_can_fit)
		self:update_scroll_info(top, bot)
	elseif not is_right then
		local top = new_item_index - 1
		local bot = #lists - (top + list_can_fit)
		self:update_scroll_info(top, bot)
	end
	return true
end

---@param target_index number
---@param should_focus? boolean
function M:scroll_to_a_list(target_index, should_focus)
	if should_focus == nil then
		should_focus = true
	end
	local lists = self.ctx.lists
	local target_item = lists[target_index]
	if not target_item then
		return
	end

	-- All items alrady in view so just focus on the item
	local item_can_fit = self:item_can_fit()
	if should_focus and item_can_fit >= #lists and target_item:in_view() then
		target_item:focus()
		return
	end

	local top_item_index = target_index
	local items_count_from_target = #lists - (target_index - 1)
	local target_can_fit_top = items_count_from_target >= item_can_fit

	if not target_can_fit_top then
		-- Info: top_item_index can be negative
		top_item_index = target_index - (item_can_fit - items_count_from_target)
	end
	local bottom_item_index = top_item_index + (item_can_fit - 1)

	local visual_index = 0
	for index, list in ipairs(lists) do
		if index >= top_item_index and index <= bottom_item_index then
			visual_index = visual_index + 1
			list:update_visible_position(visual_index)
		else
			list:update_visible_position(nil)
		end
	end

	-- Update scroll info
	local top, bot = top_item_index - 1, #lists - bottom_item_index
	self:update_scroll_info(top, bot)

	if should_focus then
		target_item:focus()
	end
end

function M:jump_to_first_list()
	local lists = self.ctx.lists
	if #lists == 0 then
		return
	end

	local list_can_fit = self:item_can_fit()

	if lists[1]:has_visual_index() or not lists[1]:closed() then
		lists[1]:focus()
		-- list:update_scroll_info(0, 0)
		return
	end

	for index = 1, #lists, 1 do
		local list = lists[index]
		if list_can_fit >= index then
			list:update_visible_position(index)
		else
			list:update_visible_position(nil)
		end
	end

	lists[1]:focus()

	local top = 0
	local bot = #lists - list_can_fit
	self:update_scroll_info(top, bot)
end

function M:jump_to_last_list()
	local lists = self.ctx.lists
	if #lists == 0 then
		return
	end

	if lists[#lists]:has_visual_index() or not lists[#lists]:closed() then
		lists[#lists]:focus()
		-- list:update_scroll_info(0, 0)
		return
	end

	local list_can_fit = self:item_can_fit()

	if #lists < list_can_fit then
		list_can_fit = #lists
	end

	for index = #lists, 1, -1 do
		local tk = lists[index]
		if list_can_fit > 0 then
			tk:update_visible_position(list_can_fit)
			list_can_fit = list_can_fit - 1
		else
			tk:update_visible_position(nil)
		end
	end

	lists[#lists]:focus()

	local bot = 0
	local top = #lists - self:item_can_fit()
	self:update_scroll_info(top, bot)
end

return M
