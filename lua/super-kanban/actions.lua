local utils = require("super-kanban.utils")
local actions = {}

actions.close = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		ctx.board:exit()
	end

	return { callback = callback, desc = "Close SuperKanban" }
end

actions.create_task = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end

		listUI:create_task()
	end

	return { callback = callback, desc = "Create a new task" }
end

actions.delete_task = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not taskUI then
			return
		end
		taskUI:delete_task()
	end

	return { callback = callback, desc = "Delete task" }
end

actions.create_list = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		vim.api.nvim_exec_autocmds("BufLeave", {})
		vim.ui.input({
			prompt = "Enter a name for the new list:",
		}, function(name)
			if name then
				ctx.board:create_list(name)
			end
		end)
	end

	return { callback = callback, desc = "Create list" }
end

actions.delete_list = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end
		listUI:delete_list()
	end

	return { callback = callback, desc = "Delete list" }
end

actions.rename_list = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
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

actions.pick_date = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not taskUI then
			return
		end
		taskUI:pick_date()
	end

	return { callback = callback, desc = "Pick due date" }
end

actions.log_info = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if taskUI then
			dd(taskUI.data.title, string.format("index %s, visual_index %s", taskUI.index, taskUI.visible_index))
		end

		-- if listUI then
		-- 	dd(listUI.data.title, string.format("index %s, visual_index %s", listUI.index, listUI.visible_index))
		-- end

		if listUI and _G.log then
			local list = ctx.lists[listUI.index]
			for _, item in ipairs(list.tasks) do
				log(item.data.title, string.format("index %s, visual_index %s", item.index, item.visible_index))
			end
		end
	end

	return { callback = callback, desc = "Print task info" }
end

---@param direction "left"|"right"|"up"|"down"
actions.swap = function(direction)
	direction = direction or "down"
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not taskUI then
			return
		end

		local swap_directions = {
			left = function()
				taskUI:swap_horizontal(-1)
			end,
			right = function()
				taskUI:swap_horizontal(1)
			end,
			up = function()
				taskUI:swap_vertical(-1)
			end,
			down = function()
				taskUI:swap_vertical(1)
			end,
		}

		swap_directions[direction]()
	end

	return { callback = callback, desc = "Swap task " .. direction }
end

---@param direction "left"|"right"
actions.swap_list = function(direction)
	direction = direction or "down"

	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end

		local swap_directions = {
			left = function()
				listUI:swap_horizontal(-1)
			end,
			right = function()
				listUI:swap_horizontal(1)
			end,
		}

		swap_directions[direction]()
	end

	return { callback = callback, desc = "Swap with " .. direction .. " list" }
end

---@param direction "left"|"right"|"up"|"down"|"first"|"last"
actions.jump = function(direction)
	direction = direction or "down"

	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		local swap_directions = {
			left = function()
				if taskUI then
					taskUI:jump_horizontal(-1)
				elseif listUI then
					listUI:jump_horizontal(-1)
				end
			end,
			right = function()
				if taskUI then
					taskUI:jump_horizontal(1)
				elseif listUI then
					listUI:jump_horizontal(1)
				end
			end,
			up = function()
				if taskUI then
					taskUI:jump_vertical(-1)
				end
			end,
			down = function()
				if taskUI then
					taskUI:jump_vertical(1)
				end
			end,
			first = function()
				if listUI then
					listUI:jump_to_first_task()
				end
			end,
			last = function()
				if listUI then
					listUI:jump_to_last_task()
				end
			end,
		}

		swap_directions[direction]()
	end

	return { callback = callback, desc = "Jump to " .. direction .. "task" }
end

---@param direction "left"|"right"|"first"|"last"
actions.jump_list = function(direction)
	direction = direction or "down"

	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end

		local swap_directions = {
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

		swap_directions[direction]()
	end

	return { callback = callback, desc = "Jump to " .. direction .. " list" }
end

actions.search = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		require("lua.super-kanban.pickers.snacks").search_tasks({}, ctx, taskUI or listUI)
	end

	return { callback = callback, desc = "Search", nowait = true }
end

return actions
