local hl = require("super-kanban.highlights")

---@class superkanban.RootUI
---@field win snacks.win
---@overload fun(config :{}): superkanban.RootUI
local M = setmetatable({}, {
	__call = function(t, ...)
		return t.new(...)
	end,
})
M.__index = M

---@type superkanban.Config
local config

---@param conf superkanban.Config
function M.new(conf)
	local self = setmetatable({}, M)

	local root_win = Snacks.win({
		-- file = fname,
		-- width = 0.8,
		-- height = 0.8,
		-- col = 1,
		enter = false,
		width = 0,
		height = vim.o.lines - 2,
		-- border = "rounded",
		border = { "", " ", "", "", "", "", "", "" },
		focusable = true,
		zindex = 10,
		wo = {
			winhighlight = hl.root,
			winbar = string.format(
				"%%#KanbanWinbar#%%= %%#KanbanFileTitleAlt#%%#KanbanFileTitle#%s%%#KanbanFileTitleAlt#%%#KanbanWinbar# %%=",
				"Kanban"
			),
		},
		bo = {
			modifiable = false,
			filetype = "superkanban_board",
		},
	})

	self.win = root_win
	config = conf
	return self
end

---@param ctx superkanban.Ctx
function M:init(ctx)
	self:set_actions(ctx)
	self:set_events(ctx)

	for _, list in ipairs(ctx.lists) do
		list:init(ctx)
	end

	local focus_loc = ctx.focus_location
	if focus_loc then
		ctx.lists[focus_loc[1]].tasks[focus_loc[2]]:focus()
	elseif ctx.lists[1] then
		ctx.lists[1]:focus()
	end
end

function M:exit(ctx)
	self.win:close()
end

function M:on_exit(ctx)
	require("super-kanban.parser.markdown").write_file(ctx, config)
	for _, li in ipairs(ctx.lists) do
		li.win:close()
	end
	self.win:close()
end

---@param ctx superkanban.Ctx
function M:set_actions(ctx) end

---@param ctx superkanban.Ctx
function M:set_events(ctx)
	self.win:on("WinClosed", function(_, ev)
		self:on_exit(ctx)
	end, { win = true })

	self.win:on("BufEnter", function()
		vim.defer_fn(function()
			self.win:destroy()
		end, 10)
	end, { buf = true })
end

return M
