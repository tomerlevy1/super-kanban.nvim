local Task = require("super-kanban.ui.task")

local actions = {}

actions.close = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		ctx.board:exit()
	end

	return {
		callback = callback,
		desc = "Close superkanban",
	}
end

actions.create_task = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end

		local list = ctx.lists[listUI.index]
		local target_index = #list.tasks + 1

		local task_can_fit = list:task_can_fit()
		local list_space_available = #list.tasks < task_can_fit

		local new_task = Task({
			data = {
				title = "",
				check = " ",
				tag = {},
				due = {},
			},
			list_index = list.index,
			index = target_index,
			ctx = ctx,
		}):mount(list, {
			visible_index = list_space_available and target_index or nil,
		})
		list.tasks[target_index] = new_task

		list:jump_bottom()
		vim.cmd.startinsert()
	end

	return {
		callback = callback,
		desc = "Create a new task",
	}
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

	return {
		callback = callback,
		desc = "Delete task",
	}
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

	return {
		callback = callback,
		desc = "Delete task",
	}
end

actions.log = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if taskUI then
			dd(taskUI.data.title, string.format("index %s, visual_index %s", taskUI.index, taskUI.visible_index))
		end

		if listUI then
			local list = ctx.lists[listUI.index]
			for _, tk in ipairs(list.tasks) do
				log(tk.data.title, string.format("index %s, visual_index %s", tk.index, tk.visible_index))
			end
		end
	end

	return {
		callback = callback,
		desc = "Delete task",
	}
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

	return {
		callback = callback,
		desc = "Swap task " .. direction,
	}
end

---@param direction "left"|"right"|"up"|"down"
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
		}

		swap_directions[direction]()
	end

	return {
		callback = callback,
		desc = "Jump " .. direction,
	}
end

---@param direction "left"|"right"
actions.jump_list = function(direction)
	direction = direction or "down"

	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		local swap_directions = {
			left = function()
				if listUI then
					listUI:jump_horizontal(-1)
				end
			end,
			right = function()
				if listUI then
					listUI:jump_horizontal(1)
				end
			end,
		}

		swap_directions[direction]()
	end

	return { callback = callback, desc = "Jump list " .. direction }
end

actions.top_task = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end
		listUI:jump_top()
	end

	return { callback = callback, desc = "Top task" }
end

actions.bottom_task = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end
		listUI:jump_bottom()
	end

	return { callback = callback, desc = "Bottom task" }
end

actions.top_list = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end
		ctx.board:jump_top()
	end

	return { callback = callback, desc = "Top list" }
end

actions.bottom_list = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		if not listUI then
			return
		end
		ctx.board:jump_bottom()
	end

	return { callback = callback, desc = "Bottom list" }
end

actions.search = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		require("lua.super-kanban.pickers.snacks").search_tasks({}, ctx, taskUI or listUI)
	end

	return {
		callback = callback,
		desc = "Search",
		nowait = true,
	}
end

actions.create_list = function()
	---@param taskUI superkanban.TaskUI|nil
	---@param listUI superkanban.TaskListUI|nil
	---@param ctx superkanban.Ctx
	local callback = function(taskUI, listUI, ctx)
		ctx.board:create_list()
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

return actions
