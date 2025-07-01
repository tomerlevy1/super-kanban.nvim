local text = require('super-kanban.utils.text')
local constants = require('super-kanban.constants')

local M = {}

---@param item any
---@param ctx superkanban.Ctx
local function focus_card_on_confirm(item, ctx)
  local list = ctx.lists[item.value.list_index]
  local list_was_in_view = true
  if not list:in_view() then
    list_was_in_view = false
    ctx.board:scroll_to_a_list(list.index, false)
  end

  local card = list.cards[item.value.index]
  if list_was_in_view and card:in_view() then
    card:focus()
  else
    list:scroll_to_a_card(card.index, true)
  end
end

---@param opts snacks.picker.Config
---@param ctx superkanban.Ctx
---@param active_item superkanban.cardUI|superkanban.ListUI|nil
function M.search_cards(opts, ctx, active_item)
  local status_ok, snack_picker = pcall(require, 'snacks.picker')
  if not status_ok then
    vim.notify('snacks.nvim not found', vim.log.levels.ERROR)
    return
  end

  local found_item = nil

  ---@type snacks.picker.Config
  local picker_conf = {
    confirm = function(p, item)
      if item then
        found_item = true
        focus_card_on_confirm(item, ctx)
      end
      p:close()
    end,
    on_close = function()
      vim.schedule(function()
        if not found_item and active_item and not active_item:closed() then
          active_item:focus()
        end
      end)
    end,
    title = 'Super Kanban',
    preview = 'preview',
    -- format = 'text',
    format = function(item, _)
      local ret = {} ---@type snacks.picker.Highlight[]
      local title = item.text:gsub('<br>', '')
      ret[#ret + 1] = { title }
      return ret
    end,
    layout = {
      preset = 'ivy',
      layout = {
        height = 0.4,
      },
    },
    finder = function()
      local items = {}
      for _, list in ipairs(ctx.lists) do
        for _, card in ipairs(list.cards) do
          items[#items + 1] = {
            text = card.data.title,
            preview = {
              text = table.concat(text.get_buf_lines_from_task(card.data), '\n'),
              ft = constants.card.filetype,
            },
            value = {
              data = card.data,
              index = card.index,
              list_index = card.list_index,
            },
          }
        end
      end

      return items
    end,
  }

  opts = vim.tbl_extend('force', picker_conf, opts or {})
  snack_picker.pick(nil, opts)
end

---@param opts snacks.picker.Config
---@param active_item superkanban.cardUI|superkanban.ListUI|nil
function M.files(opts, active_item)
  local status_ok, snack_picker = pcall(require, 'snacks.picker')
  if not status_ok then
    vim.notify('snacks.nvim not found', vim.log.levels.ERROR)
    return
  end

  local found_item = nil

  ---@type snacks.picker.Config
  local picker_conf = {
    confirm = function(p, item)
      if item then
        found_item = true
        require('super-kanban').open(item.file)
      end
      p:close()
    end,
    on_close = function()
      vim.schedule(function()
        if not found_item and active_item and not active_item:closed() then
          active_item:focus()
        end
      end)
    end,
    title = 'Super Kanban',
    layout = {
      preset = 'ivy',
      layout = {
        height = 0.4,
      },
    },
    ft = { 'md', 'org' },
  }

  opts = vim.tbl_extend('force', picker_conf, opts or {})
  snack_picker.files(opts)
end

return M
