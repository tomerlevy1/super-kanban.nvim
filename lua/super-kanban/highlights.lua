-- %#KanbanFileTitle#

local make_winhighlight = function(highlight)
	return table.concat(
		vim.tbl_map(function(key)
			return key .. ":" .. highlight[key]
		end, vim.tbl_keys(highlight)),
		","
	)
end

local hls = {
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

return hls
