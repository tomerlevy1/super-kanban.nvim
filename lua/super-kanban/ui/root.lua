local hl = require("super-kanban.highlights")

---@class superkanban.RootUI
---@field win snacks.win
---@field ctx superkanban.Ctx
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

	config = conf
	return self
end

---@param ctx superkanban.Ctx
function M:mount(ctx)
	self:set_actions(ctx)
	self:set_events(ctx)

	for _, list in ipairs(ctx.lists) do
		list:mount(ctx)
	end

	local focus_loc = ctx.focus_location
	if focus_loc then
		ctx.lists[focus_loc[1]].tasks[focus_loc[2]]:focus()
	elseif ctx.lists[1] then
		ctx.lists[1]:focus()
	end

	self.ctx = ctx
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

---@param ctx superkanban.Ctx
function M:set_actions(ctx) end

---@param ctx superkanban.Ctx
function M:set_events(ctx)
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
