local actions = {}

actions.close = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		ctx.board:exit()
	end

	return { callback = callback, desc = "Close SuperKanban" }
end

---@param placement? "first"|"last"
actions.create_card = function(placement)
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not listUI then
			return
		end

		listUI:create_card(placement)
	end

	return { callback = callback, desc = "Create a new card" }
end

actions.delete_card = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not cardUI then
			return
		end
		cardUI:delete_card()
	end

	return { callback = callback, desc = "Delete card" }
end

actions.toggle_complete = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
    if not cardUI then
      return
    end

    cardUI:toggle_complete()
	end

	return { callback = callback, desc = "Toggle Complete" }
end

---@param placement? "first"|"last"
actions.create_list = function(placement)
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		vim.api.nvim_exec_autocmds("BufLeave", {})
		vim.ui.input({
			prompt = "Enter a name for the new list:",
		}, function(name)
			if name then
				ctx.board:create_list(name, placement)
			end
		end)
	end

	return { callback = callback, desc = "Create list" }
end

actions.delete_list = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not listUI then
			return
		end
		listUI:delete_list()
	end

	return { callback = callback, desc = "Delete list" }
end

actions.rename_list = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not listUI then
			return
		end

		vim.api.nvim_exec_autocmds("BufLeave", {})
		vim.ui.input({
			prompt = "Rename list:",
			default = listUI.data.title,
		}, function(name)
			if name then
				listUI:rename_list(name)
			end
		end)
	end

	return { callback = callback, desc = "Rename list" }
end

---@param direction? '"newest_first"'|'"oldest_first"'
actions.sort_cards_by_due = function(direction)
  direction = direction or "newest_first"
	vim.validate({
		direction = {
			direction,
			function(d)
				return d == "newest_first" or d == "oldest_first"
			end,
			"must be 'newest_first' or 'oldest_first'",
		},
	})

	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not listUI then
			return
		end

		listUI:sort_cards_by_due(direction)
	end

	return { callback = callback, desc = "Sort list" }
end

actions.pick_date = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not cardUI then
			return
		end
		cardUI:pick_date()
	end

	return { callback = callback, desc = "Pick due date" }
end

actions.log_info = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if cardUI then
			dd(cardUI.data.title, string.format("index %s, visual_index %s", cardUI.index, cardUI.visible_index))
		end

		-- if listUI then
		-- 	dd(listUI.data.title, string.format("index %s, visual_index %s", listUI.index, listUI.visible_index))
		-- end

		if listUI and _G.log then
			local list = ctx.lists[listUI.index]
			for _, item in ipairs(list.cards) do
				log(item.data.title, string.format("index %s, visual_index %s", item.index, item.visible_index))
			end
		end
	end

	return { callback = callback, desc = "Print card info" }
end

---@param direction "left"|"right"|"up"|"down"
actions.move = function(direction)
	direction = direction or "down"
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not cardUI then
			return
		end

		local move_directions = {
			left = function()
				cardUI:move_horizontal(-1)
			end,
			right = function()
				cardUI:move_horizontal(1)
			end,
			up = function()
				cardUI:move_vertical(-1)
			end,
			down = function()
				cardUI:move_vertical(1)
			end,
		}

		move_directions[direction]()
	end

	return { callback = callback, desc = "Move card to " .. direction }
end

---@param direction "left"|"right"
actions.move_list = function(direction)
	direction = direction or "down"

	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not listUI then
			return
		end

		local move_directions = {
			left = function()
				listUI:move_horizontal(-1)
			end,
			right = function()
				listUI:move_horizontal(1)
			end,
		}

		move_directions[direction]()
	end

	return { callback = callback, desc = "Move list to " .. direction }
end

---@param direction "left"|"right"|"up"|"down"|"first"|"last"
actions.jump = function(direction)
	direction = direction or "down"

	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		local move_directions = {
			left = function()
				if cardUI then
					cardUI:jump_horizontal(-1)
				elseif listUI then
					listUI:jump_horizontal(-1)
				end
			end,
			right = function()
				if cardUI then
					cardUI:jump_horizontal(1)
				elseif listUI then
					listUI:jump_horizontal(1)
				end
			end,
			up = function()
				if cardUI then
					cardUI:jump_vertical(-1)
				end
			end,
			down = function()
				if cardUI then
					cardUI:jump_vertical(1)
				end
			end,
			first = function()
				if listUI then
					listUI:jump_to_first_card()
				end
			end,
			last = function()
				if listUI then
					listUI:jump_to_last_card()
				end
			end,
		}

		move_directions[direction]()
	end

	return { callback = callback, desc = "Jump to " .. direction .. "card" }
end

---@param direction "left"|"right"|"first"|"last"
actions.jump_list = function(direction)
	direction = direction or "down"

	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		if not listUI then
			return
		end

		local move_directions = {
			left = function()
				listUI:jump_horizontal(-1)
			end,
			right = function()
				listUI:jump_horizontal(1)
			end,
			first = function()
				ctx.board:jump_to_first_list()
			end,
			last = function()
				ctx.board:jump_to_last_list()
			end,
		}

		move_directions[direction]()
	end

	return { callback = callback, desc = "Jump to " .. direction .. " list" }
end

actions.search = function()
	---@param cardUI superkanban.cardUI|nil
	---@param listUI superkanban.ListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(cardUI, listUI, ctx)
		require("super-kanban.pickers.snacks").search_cards({}, ctx, cardUI or listUI)
	end

	return { callback = callback, desc = "Search", nowait = true }
end

return actions
