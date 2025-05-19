local hl = require("super-kanban.highlights")
local Config = require("super-kanban.config")

---@class superkanban.RootUI
---@field win snacks.win
---@field ctx superkanban.Ctx
---@field type "root"
---@field scroll_info {first:number,last:number}
---@overload fun(config :{}): superkanban.RootUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M
---@type superkanban.Config
local config

local function winbar(title)
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
		wo = { winhighlight = hl.root, winbar = winbar("Kanban") },
		bo = { modifiable = false, filetype = "superkanban_board" },
	})

	self.type = "root"
	self.scroll_info = { first = 0, last = 0 }

	return self
end

---@param ctx superkanban.Ctx
function M:mount(ctx)
	self:set_actions()
	self:set_events()

	local list_can_fit = self:list_can_fit()
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

function M:list_can_fit()
	local width = self.win:size().width - 2 - Config.board.padding.left
	return math.floor(width / config.list_min_width)
end

---@param direction number
---@param cur_list_index? number
function M:scroll_list(direction, cur_list_index)
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

	local list_can_fit = self.ctx.root:list_can_fit()
	local new_item_index, new_item_visual_index = nil, nil
	local hide_task_index = nil

	for index, item in ipairs(lists) do
		if item:has_visual_index() then
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

function M:update_scroll_info(first, last)
	self.scroll_info.first = first > 0 and first or 0
	self.scroll_info.last = last > 0 and last or 0

	vim.api.nvim_win_set_config(self.win.win, {
		title = string.format("← %d | %d →  ", self.scroll_info.first, self.scroll_info.last),
		title_pos = "right",
	})
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

function M:set_actions() end

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

return M
