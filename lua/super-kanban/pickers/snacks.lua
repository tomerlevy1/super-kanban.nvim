local utils = require("super-kanban.utils")

local M = {}

---@param item any
---@param ctx superkanban.Ctx
local function focus_task_on_confirm(item, ctx)
	local list = ctx.lists[item.value.list_index]
  local list_was_in_view = true
	if not list:in_view() then
    list_was_in_view = false
		ctx.board:scroll_to_a_list(list.index, false)
	end

	local task = list.tasks[item.value.index]
	if list_was_in_view and task:in_view() then
    task:focus()
	else
		list:scroll_to_a_task(task.index, true)
	end
end

---@param opts snacks.picker.Config
---@param ctx superkanban.Ctx
---@param current_item superkanban.TaskUI|superkanban.TaskListUI|nil
function M.search_tasks(opts, ctx, current_item)
	local status_ok, snack_picker = pcall(require, "snacks.picker")
	if not status_ok then
		vim.notify("snacks.nvim not found", vim.log.levels.ERROR)
		return
	end

	local found_item = nil

	---@type snacks.picker.Config
	local picker_conf = {
		confirm = function(p, item)
			if item then
				found_item = true
				focus_task_on_confirm(item, ctx)
			end
			p:close()
		end,
		on_close = function()
			vim.schedule(function()
				if not found_item then
					current_item:focus()
				end
			end)
		end,
		title = "Super Kanban",
		format = "text",
		preview = "preview",
		layout = {
			-- preview = "main",
			preset = "ivy",
			layout = {
				height = 0.4,
			},
		},
		-- format = function(item, _)
		-- 	-- local kind = navic.adapt_lsp_num_to_str(item.value.kind)
		-- 	-- local kind_hl = "Navbuddy" .. kind

		-- 	local ret = {} ---@type snacks.picker.Highlight[]
		-- 	-- ret[#ret + 1] = { Snacks.picker.util.align(tostring(kind), 15), kind_hl }
		-- 	ret[#ret + 1] = { item.text }
		-- 	return ret
		-- end,
		finder = function()
			local items = {}
			for _, list in ipairs(ctx.lists) do
				for _, task in ipairs(list.tasks) do
					items[#items + 1] = {
						text = task.data.title,
						preview = {
							text = table.concat(utils.get_lines_from_task(task.data), "\n"),
							ft = "superkanban_task",
						},
						value = {
							data = task.data,
							index = task.index,
							list_index = task.list_index,
						},
					}
				end
			end

			return items
		end,
	}

	opts = vim.tbl_extend("force", picker_conf, opts or {})
	snack_picker.pick(nil, opts)
end

return M
