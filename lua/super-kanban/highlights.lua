local c = {
	none = "NONE",
	bg0 = "#242b38",
	bg1 = "#2d3343",
	bg2 = "#343e4f",
	bg3 = "#363c51",
	bg_d = "#1e242e",
	bg_d2 = "#1b222c",
	black = "#151820",

	fg = "#abb2bf",
	light_grey = "#8b95a7",
	grey = "#546178",
	white = "#dfdfdf",
	muted = "#68707E",
	layer = "#3E425D",

	red = "#ef5f6b",
	green = "#97ca72",
	orange = "#d99a5e",
	yellow = "#ebc275",
	blue = "#5ab0f6",
	purple = "#ca72e4",
	cyan = "#4dbdcb",

	diff_add = "#303d27",
	diff_change = "#18344c",
	diff_delete = "#3c2729",
	diff_text = "#265478",

	bg_yellow = "#f0d197",
	bg_blue = "#6db9f7",

	dim_red = "#4D3542",
	dim_green = "#3B4048",
	dim_yellow = "#4C4944",
	dim_blue = "#204364",
	dim_purple = "#45395A",
	dim_cyan = "#2C4855",

	-- #777700
	dark_purple = "#8f36a9",
	dark_red = "#a13131",
	dark_orange = "#9a6b16",
	dark_blue = "#127ace",
	dark_green = "#5e9437",
	dark_cyan = "#25747d",

	ligh_green = "#00a86d",
}

-- %#KanbanFileTitle#
local make_winhighlight = function(highlight)
	return table.concat(
		vim.tbl_map(function(key)
			return key .. ":" .. highlight[key]
		end, vim.tbl_keys(highlight)),
		","
	)
end

local M = {
	root = make_winhighlight({
		Normal = "KanbanNormal",
		NormalNC = "KanbanNormal",
	}),
	list = make_winhighlight({
		Normal = "KanbanListNormal",
		NormalNC = "KanbanListNormal",
		FloatBorder = "KanbanListBorder",
		FloatTitle = "KanbanListTitle",
	}),
	task = make_winhighlight({
		Normal = "KanbanTaksNormal",
		NormalNC = "KanbanTaksNormalNC",
		WinBar = "KanbanTaksWinbarActive",
		WinBarNC = "KanbanTaksWinbar",
		FloatBorder = "KanbanTaksSeparator",
	}),
	taskActive = make_winhighlight({
		Normal = "KanbanTaksNormal",
		NormalNC = "KanbanTaksNormalNC",
		WinBar = "KanbanTaksWinbarActive",
		WinBarNC = "KanbanTaksWinbar",
		FloatBorder = "KanbanTaksSeparatorActive",
	}),
}

function M.create_winhighlights()
	local float_bg = "#21252B"
  -- stylua: ignore
  local highlights = {
    KanbanNormal                = { fg = c.fg, bg = c.none },
    KanbanWinbar                = { link = 'KanbanNormal' },
    KanbanFileTitle             = { fg = c.bg0, bg = c.orange },
    KanbanFileTitleAlt          = { fg = c.orange, bg = c.bg0 },
    KanbanListNormal            = { link = 'KanbanNormal' },
    KanbanListBorder            = { fg = c.cyan, bg = c.none },
    KanbanListTitle             = { fg = c.green, bg = c.none },

    KanbanTaksTag               = { fg = c.yellow, bg = c.dim_yellow },
    KanbanDueDate               = { fg = '#8a5cf5' },
    KanbanDueDateShort          = { fg = '#8a5cf5'  },
    KanbanTaksNormal            = { fg = c.fg, bg = float_bg },
    KanbanTaksNormalNC          = { fg = c.fg, bg = c.none },
    KanbanTaksSeparator         = { fg = c.cyan, bg = c.none },
    KanbanTaksSeparatorActive   = { fg = c.cyan, bg = float_bg },
    KanbanTaksWinbar            = { fg = c.muted, bg = c.none },
    KanbanTaksWinBarActive      = { fg = c.green, bg = float_bg },
  }

	for hl_name, option in pairs(highlights) do
		vim.api.nvim_set_hl(0, hl_name, option)
	end
end

return M
