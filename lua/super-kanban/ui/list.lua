local hl = require("super-kanban.highlights")
local utils = require("super-kanban.utils")
local Card = require("super-kanban.ui.card")
local text = require("super-kanban.utils.text")
local date = require("super-kanban.utils.date")

---@class superkanban.List.Opts
---@field data {title: string}
---@field index number
---@field ctx superkanban.Ctx

---@class superkanban.ListUI
---@field data {title: string}
---@field index number
---@field visible_index number
---@field win snacks.win
---@field ctx superkanban.Ctx
---@field type "list"
---@field scroll_info {top:number,bot:number}
---@overload fun(opts:superkanban.List.Opts): superkanban.ListUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@param index number
---@param conf superkanban.Config
---@return {row:number,col:number}
local function get_list_position(index, conf)
	local col = conf.board.padding.left + (conf.list.width + 3) * (index - 1)
	return { row = conf.board.padding.top, col = col }
end

---@param opts superkanban.List.Opts
function M.new(opts)
	---@diagnostic disable-next-line: param-type-mismatch
	local self = setmetatable({}, M)

	self.ctx = opts.ctx
	self.data = opts.data
	self.index = opts.index
	self.scroll_info = { top = 0, bot = 0 }
	self.type = "list"

	return self
end

function M:setup_win()
	local conf = self.ctx.config
	local pos = get_list_position(self.index, conf)

	self.win = Snacks.win({
		-- User cofig values
		width = conf.list.width,
		height = conf.list.height,
		border = conf.list.border,
		zindex = conf.list.zindex,
		wo = utils.merge({
			winhighlight = hl.list,
			winbar = self:generate_winbar(self.data.title, ""),
		}, conf.list.win_options),
		-- Non cofig values
		win = self.ctx.board.win.win,
		row = pos.row,
		col = pos.col,
		enter = false,
		show = false,
		relative = "win",
		focusable = true,
		keys = { q = false },
		bo = { modifiable = false, filetype = "superkanban_list" },
		on_win = function()
			vim.schedule(function()
				self:set_keymaps()
				self:set_events(self.ctx)
			end)

			local list = self.ctx.lists[self.index]
			if not list then
				return
			end

			local item_can_fit = self:item_can_fit()
			local first_hidden_card_index = 0

			for index, card in ipairs(list.cards) do
				-- calcuate available space for list
				local card_win = card:setup_win(list)
				local space_available = item_can_fit >= index

				if not space_available and first_hidden_card_index == 0 then
					first_hidden_card_index = index
				end

				card:mount(list, {
					win = card_win,
					visible_index = space_available and index or nil,
				})
			end

			-- Set footer
			self:update_scroll_info(
				0,
				first_hidden_card_index > 0 and #list.cards + 1 - first_hidden_card_index or 0,
				#list.cards
			)
		end,
	})
	return self.win
end

---@param opts? {visible_index?:number}
function M:mount(opts)
	opts = opts or {}

	self:setup_win()

	if type(opts.visible_index) == "number" then
		self.visible_index = opts.visible_index
		self.win:show()
	end

	return self
end

function M:find_first_visible_card()
	for _, card in ipairs(self.ctx.lists[self.index].cards) do
		if card:has_visual_index() then
			return card
		end
	end

	return nil
end

function M:find_a_visible_card(visible_index)
	local cards = self.ctx.lists[self.index].cards
	for index = visible_index, #cards, 1 do
		local card = cards[index]
		if card.visible_index == visible_index then
			return card
		end
	end

	return nil
end

function M:focus()
	local card = self.ctx.lists[self.index].cards
	if not self:in_view() then
		return false
	end

	if #card > 0 then
		(self:find_first_visible_card() or card[1]):focus()
		return true
	end

	self.win:focus()
	return true
end

function M:exit()
	self.win:close()
	self.visible_index = nil
end

function M:update_scroll_info(top, bottom, total)
	self.scroll_info.top = top > 0 and top or 0
	self.scroll_info.bot = bottom > 0 and bottom or 0
	self:update_winbar(total)

	vim.api.nvim_win_set_config(self.win.win, {
		footer = {
			{ "↑" .. tostring(self.scroll_info.top) },
			{ "-", "KanbanListBorder" },
			{ "↓" .. tostring(self.scroll_info.bot) },
		},
		footer_pos = "center",
	})
end

function M:item_can_fit()
	local height = self.win:size().height - 3
	return math.floor(height / (self.ctx.config.card.height + 1))
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

---@param new_index? number
function M:update_visible_position(new_index)
	if type(new_index) == "number" and new_index > 0 then
		self.win.opts.col = get_list_position(new_index, self.ctx.config).col

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

local f_winbar = "║ %s %%= %s ║"

---@param title string
---@param count string
function M:generate_winbar(title, count)
	return f_winbar:format(title, count)
end

---@param card_count number
function M:update_winbar(card_count)
	if type(card_count) == "number" then
		local count = card_count == 0 and "" or tostring(card_count)
		vim.api.nvim_set_option_value("winbar", self:generate_winbar(self.data.title, count), { win = self.win.win })
	end
end

---@param opts {from:number,to:number}
function M:fill_empty_space(opts)
	local cards = self.ctx.lists[self.index].cards
	local item_can_fit = self:item_can_fit()

	local empty_spaces = opts.to - opts.from
	local last_used_visible_index = 0

	for index = opts.to, #cards, 1 do
		local item = cards[index]
		item.index = item.index - 1

		if item:in_view() then
			last_used_visible_index = item.visible_index - 1
			item:update_visible_position(last_used_visible_index)
		elseif empty_spaces > 0 and last_used_visible_index < item_can_fit then
			-- dd(item.data.title)
			last_used_visible_index = last_used_visible_index == 0 and item_can_fit or last_used_visible_index + 1
			item:update_visible_position(last_used_visible_index)

			-- Update scroll info for bottom
			self:update_scroll_info(self.scroll_info.top, self.scroll_info.bot - 1, #cards)
			empty_spaces = empty_spaces - 1
		end
	end

	while empty_spaces > 0 do
		self:scroll_list(-1, 0)
		empty_spaces = empty_spaces - 1
	end
end

---A hack to Combine list and cards in ctx a type safe way
---@param list table
---@param cards superkanban.cardUI
---@return superkanban.List.Ctx
function M.generate_list_ctx(list, cards)
	list.cards = cards
	return list
end

---@param ctx superkanban.Ctx
function M:set_events(ctx)
	self.win:on("WinClosed", function()
		for _, card in ipairs(ctx.lists[self.index].cards) do
			card:exit()
		end
	end, { win = true })

	self.win:on("BufEnter", function()
		local card = ctx.lists[self.index].cards[1]
		if card then
			card:focus()
		end
	end, { buf = true })
end

function M:set_keymaps()
	local buffer = self.win.buf

	for lhs, rhs in pairs(self.ctx.config.mappinngs) do
		vim.keymap.set("n", lhs, function()
			rhs.callback(nil, self.ctx.lists[self.index], self.ctx)
		end, utils.merge({ buffer = buffer }, rhs))
	end
end

---@param placement? "first"|"last"
function M:create_card(placement)
	placement = placement or "first"

	local list = self.ctx.lists[self.index]
	local target_index = 1
	local visual_index = nil

	if placement == "first" then
		for _, card in pairs(list.cards) do
			card.index = card.index + 1
		end
	elseif placement == "last" then
		target_index = #list.cards + 1
		local item_can_fit = list:item_can_fit()
		local list_space_available = #list.cards < item_can_fit

		if list_space_available then
			visual_index = target_index
		end
	end

	local new_card = Card({
		data = Card.empty_data(),
		list_index = list.index,
		index = target_index,
		ctx = self.ctx,
	}):mount(list, { visible_index = visual_index })
	table.insert(list.cards, target_index, new_card)

	if placement == "last" then
		list:jump_to_last_card()
	else
		list:jump_to_first_card()
	end
	vim.cmd.startinsert()
end

---@param should_focus? boolean
function M:delete_list(should_focus)
	local target_index = self.index
	self:exit()
	table.remove(self.ctx.lists, target_index)

	self.ctx.board:fill_empty_space({ from = target_index - 1, to = target_index })

	if should_focus ~= false then
		local focus_target = self.ctx.lists[target_index] or self.ctx.lists[target_index - 1]
		if focus_target then
			focus_target:focus()
		else
			self.ctx.board:exit()
		end
	end
end

---@param new_name? string
function M:rename_list(new_name)
	new_name = text.trim(new_name)
	if not new_name or new_name == "" or new_name == self.data.title then
		return
	end

	self.data.title = new_name
	self.win:set_title({ { self.data.title } }, "center")
end

function M:jump_horizontal(direction)
	if direction == nil then
		direction = 1
	end
	local target_list = self.ctx.lists[self.index + direction]
	if not target_list then
		return
	end

	if not target_list:has_visual_index() or target_list:closed() then
		self.ctx.board:scroll_board(direction, self.index)
	end
	target_list:focus()
end

function M:move_horizontal(direction)
	if direction == nil then
		direction = 1
	end

	if
		(#self.ctx.lists == 1)
		or (direction == 1 and self.index == #self.ctx.lists)
		or (direction == -1 and self.index == 1)
	then
		return
	end

	-- Update index
	local cur_index = self.index
	local target_index = self.index + direction
	local cur_list = self.ctx.lists[cur_index]
	local target_list = self.ctx.lists[target_index]

	if not target_list then
		return
	end

	if target_list:closed() then
		self.ctx.board:scroll_board(direction)
	end

	-- Swap index & list in ctx
	local cur_v_index, target_v_index = target_list.visible_index, cur_list.visible_index
	cur_list.index, target_list.index = target_index, cur_index
	self.ctx.lists[target_index], self.ctx.lists[cur_index] = cur_list, target_list

	cur_list:update_visible_position(cur_v_index)
	target_list:update_visible_position(target_v_index)
	cur_list:focus()

	-- Update list_index of every cards
	for _, card in pairs(target_list.cards) do
		card.list_index = target_list.index
	end
	for _, card in pairs(cur_list.cards) do
		card.list_index = cur_list.index
	end
end

function M:jump_to_first_card()
	local list = self.ctx.lists[self.index]
	if not list then
		return
	end
	if #list.cards == 0 then
		return
	end

	local item_can_fit = self:item_can_fit()

	if list.cards[1]:has_visual_index() then
		list.cards[1]:focus()
		-- list:update_scroll_info(0, 0)
		return
	end

	for index = 1, #list.cards, 1 do
		local card = list.cards[index]
		if item_can_fit >= index then
			-- dd(tk.data.title)
			card:update_visible_position(index)
		else
			card:update_visible_position(nil)
		end
	end

	list.cards[1]:focus()

	local top = 0
	local bot = #list.cards - item_can_fit
	list:update_scroll_info(top, bot, #list.cards)
end

function M:jump_to_last_card()
	local list = self.ctx.lists[self.index]
	if not list then
		return false
	end
	if #list.cards == 0 then
		return
	end

	if not list.cards[#list.cards]:closed() then
		list.cards[#list.cards]:focus()
		-- list:update_scroll_info(0, 0)
		return
	end

	local item_can_fit = self:item_can_fit()
	if #list.cards < item_can_fit then
		item_can_fit = #list.cards
	end

	for index = #list.cards, 1, -1 do
		local card = list.cards[index]
		if item_can_fit > 0 then
			card:update_visible_position(item_can_fit)
			item_can_fit = item_can_fit - 1
		else
			card:update_visible_position(nil)
		end
	end

	list.cards[#list.cards]:focus()

	local bot = 0
	local top = #list.cards - self:item_can_fit()
	list:update_scroll_info(top, bot, #list.cards)
end

---@param direction number
---@param cur_card_index? number
function M:scroll_list(direction, cur_card_index)
	local is_downward = direction == 1
	local list = self.ctx.lists[self.index]
	if #list.cards == 0 then
		return false
	end

	-- exit if top or bottom card already in view
	if is_downward and list.cards[#list.cards]:has_visual_index() then
		return false
	elseif not is_downward and list.cards[1]:has_visual_index() then
		return false
	end

	local item_can_fit = list:item_can_fit()
	local new_card_index, new_card_visual_index = nil, nil
	local hide_card_index = nil

	for index, card in ipairs(list.cards) do
		if card:has_visual_index() then
			card:update_visible_position(card.visible_index + (is_downward and -1 or 1))

			if is_downward and type(card.visible_index) == "number" then
				new_card_index, new_card_visual_index = index + 1, card.visible_index + 1
			elseif not is_downward and new_card_visual_index == nil then
				new_card_index, new_card_visual_index = index - 1, 1
				hide_card_index = new_card_index + item_can_fit
			end
		elseif is_downward and type(new_card_visual_index) == "number" then
			break
		end

		if not is_downward and index == hide_card_index then
			card:update_visible_position(nil)
			break
		end
	end

	local new_card_in_view = list.cards[new_card_index]
	if new_card_in_view then
		new_card_in_view:update_visible_position(new_card_visual_index)
	end

	if is_downward then
		local bot = #list.cards - new_card_index
		local top = #list.cards - (bot + item_can_fit)
		list:update_scroll_info(top, bot, #list.cards)
	elseif not is_downward then
		local top = new_card_index - 1
		local bot = #list.cards - (top + item_can_fit)
		list:update_scroll_info(top, bot, #list.cards)
	end

	return true
end

---@param target_index number
---@param should_focus? boolean
function M:scroll_to_a_card(target_index, should_focus)
	if should_focus == nil then
		should_focus = true
	end
	local cards = self.ctx.lists[self.index].cards
	local target_item = cards[target_index]
	if not target_item then
		return
	end

	-- All cards alrady in view so just focus on the card
	local item_can_fit = self:item_can_fit()
	if should_focus and item_can_fit >= #cards and target_item:in_view() then
		target_item:focus()
		return
	end

	local top_item_index = target_index
	local items_count_from_target = #cards - (target_index - 1)
	local target_can_fit_top = items_count_from_target >= item_can_fit

	if not target_can_fit_top then
		-- Info: top_item_index can be negative
		top_item_index = target_index - (item_can_fit - items_count_from_target)
	end
	local bottom_item_index = top_item_index + (item_can_fit - 1)

	local visual_index = 0
	for index, card in ipairs(cards) do
		if index >= top_item_index and index <= bottom_item_index then
			visual_index = visual_index + 1
			card:update_visible_position(visual_index)
		else
			card:update_visible_position(nil)
		end
	end

	-- Update scroll info
	local top, bot = top_item_index - 1, #cards - bottom_item_index
	self:update_scroll_info(top, bot, #cards)

	if should_focus then
		target_item:focus()
	end
end

---@param direction '"newest_first"'|'"oldest_first"'
function M:sort_cards_by_due(direction)
	local list = self.ctx.lists[self.index]
	if not list then
		return
	end
	if #list.cards <= 1 then
		return
	end

	local item_can_fit = self:item_can_fit()

	table.sort(list.cards, function(a, b)
		local ta, tb = date.get_due_timestamp(a.data.date), date.get_due_timestamp(b.data.date)

		-- Put nil dates at the end
		if not ta then
			return false
		end
		if not tb then
			return true
		end

		if direction == "newest_first" then
			return ta > tb
		else
			return ta < tb
		end
	end)

	for index = 1, #list.cards, 1 do
		local card = list.cards[index]
		card.index = index
		if item_can_fit >= index then
			card:update_visible_position(index)
		else
			card:update_visible_position(nil)
		end
	end

	list.cards[1]:focus()

	local top = 0
	local bot = #list.cards - item_can_fit
	list:update_scroll_info(top, bot, #list.cards)
end

return M
