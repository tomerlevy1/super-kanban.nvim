local utils = require('super-kanban.utils')

local actions = {}

---Close SuperKanban
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.close = function(cardUI, listUI, ctx)
  ctx.board:exit()
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
---@param placement? "first"|"last"
local _create_card = function(cardUI, listUI, ctx, placement)
  if not listUI then
    return
  end
  listUI:create_card(placement)
end

---Create a new card at the begin of the list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.create_card_at_begin = function(cardUI, listUI, ctx)
  _create_card(cardUI, listUI, ctx, 'first')
end

---Create a new card at the end of the list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.create_card_at_end = function(cardUI, listUI, ctx)
  _create_card(cardUI, listUI, ctx, 'last')
end

---Delete card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.delete_card = function(cardUI, listUI, ctx)
  if not cardUI then
    return
  end
  cardUI:delete_card()
end

---Toggle Complete
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.toggle_complete = function(cardUI, listUI, ctx)
  if not cardUI then
    return
  end
  cardUI:toggle_complete()
end

---Archive card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.archive_card = function(cardUI, listUI, ctx)
  if not cardUI then
    return
  end
  cardUI:move_to_archive()
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
---@param placement? "first"|"last"
local _create_list = function(cardUI, listUI, ctx, placement)
  vim.api.nvim_exec_autocmds('BufLeave', {})
  vim.ui.input({
    prompt = 'Enter a name for the new list:',
  }, function(name)
    if name then
      vim.schedule(function()
        ctx.board:create_list(name, placement)
      end)
    end
  end)
end

---Create list at the begin of the board
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.create_list_at_begin = function(cardUI, listUI, ctx)
  _create_list(cardUI, listUI, ctx, 'first')
end

---Create list at end of the board
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.create_list_at_end = function(cardUI, listUI, ctx)
  _create_list(cardUI, listUI, ctx, 'last')
end

---Delete list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.delete_list = function(cardUI, listUI, ctx)
  if not listUI then
    return
  end
  listUI:delete_list()
end

---Rename list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.rename_list = function(cardUI, listUI, ctx)
  if not listUI then
    return
  end

  vim.api.nvim_exec_autocmds('BufLeave', {})
  vim.ui.input({
    prompt = 'Rename list:',
    default = listUI.data.title,
  }, function(name)
    if name then
      vim.schedule(function()
        listUI:rename_list(name)
      end)
    end
  end)
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
---@param direction? '"newest_first"'|'"oldest_first"'
local _sort_by_due = function(cardUI, listUI, ctx, direction)
  direction = direction or 'newest_first'
  vim.validate({
    direction = {
      direction,
      function(d)
        return d == 'newest_first' or d == 'oldest_first'
      end,
      "must be 'newest_first' or 'oldest_first'",
    },
  })
  if not listUI then
    return
  end

  listUI:sort_cards_by_due(direction)
end

---Sort cards in descending order
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.sort_by_due_descending = function(cardUI, listUI, ctx)
  _sort_by_due(cardUI, listUI, ctx, 'newest_first')
end

---Sort cards in ascefnding order
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.sort_by_due_ascending = function(cardUI, listUI, ctx)
  _sort_by_due(cardUI, listUI, ctx, 'oldest_first')
end

---Pick date
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.pick_date = function(cardUI, listUI, ctx)
  if not cardUI then
    return
  end
  cardUI:pick_date()
end

---Remove date
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.remove_date = function(cardUI, listUI, ctx)
  if not cardUI then
    return
  end
  cardUI:remove_date()
end

---@param cardUI superkanban.cardUI|nil
---@param direction "left"|"right"|"up"|"down"
local function _move(cardUI, direction)
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

---Move card to left
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.move_left = function(cardUI, listUI, ctx)
  _move(cardUI, 'left')
end

---Move card to right
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.move_right = function(cardUI, listUI, ctx)
  _move(cardUI, 'right')
end

---Move card to up
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.move_up = function(cardUI, listUI, ctx)
  _move(cardUI, 'up')
end

---Move card to down
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.move_down = function(cardUI, listUI, ctx)
  _move(cardUI, 'down')
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
---@param direction "left"|"right"
local _move_list = function(cardUI, listUI, ctx, direction)
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

---Move list to left
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.move_list_left = function(cardUI, listUI, ctx)
  _move_list(cardUI, listUI, ctx, 'left')
end

---Move list to right
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.move_list_right = function(cardUI, listUI, ctx)
  _move_list(cardUI, listUI, ctx, 'right')
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
---@param direction "left"|"right"|"up"|"down"|"first"|"last"
local _jump = function(cardUI, listUI, ctx, direction)
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

---Jump to left card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_left = function(cardUI, listUI, ctx)
  _jump(cardUI, listUI, ctx, 'left')
end

---Jump to right card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_right = function(cardUI, listUI, ctx)
  _jump(cardUI, listUI, ctx, 'right')
end

---Jump to up card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_up = function(cardUI, listUI, ctx)
  _jump(cardUI, listUI, ctx, 'up')
end

---Jump to down card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_down = function(cardUI, listUI, ctx)
  _jump(cardUI, listUI, ctx, 'down')
end

---Jump to first card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_first = function(cardUI, listUI, ctx)
  _jump(cardUI, listUI, ctx, 'first')
end

---Jump to last card
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_last = function(cardUI, listUI, ctx)
  _jump(cardUI, listUI, ctx, 'last')
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
---@param direction "left"|"right"|"first"|"last"
local _jump_list = function(cardUI, listUI, ctx, direction)
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

---Jump to left list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_list_left = function(cardUI, listUI, ctx)
  _jump_list(cardUI, listUI, ctx, 'left')
end

---Jump to right list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_list_right = function(cardUI, listUI, ctx)
  _jump_list(cardUI, listUI, ctx, 'right')
end

---Jump to first list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_list_first = function(cardUI, listUI, ctx)
  _jump_list(cardUI, listUI, ctx, 'first')
end

---Jump to last list
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.jump_list_last = function(cardUI, listUI, ctx)
  _jump_list(cardUI, listUI, ctx, 'last')
end

---Search
---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.search = function(cardUI, listUI, ctx)
  require('super-kanban.pickers.snacks').search_cards({}, ctx, cardUI or listUI)
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
actions.log_info = function(cardUI, listUI, ctx)
  if cardUI then
    dd(
      string.format(
        'CardUI %s, index %s, visual_index %s, list_index %s',
        cardUI.data.title,
        cardUI.index,
        cardUI.visible_index,
        cardUI.list_index
      )
    )
  end
  if listUI then
    dd(string.format('listUI %s,index %s, visual_index %s', listUI.data.title, listUI.index, listUI.visible_index))
  end

  if listUI and _G.log then
    local list = ctx.lists[listUI.index]
    for _, item in ipairs(list.cards) do
      log(item.data.title, string.format('index %s, visual_index %s', item.index, item.visible_index))
    end
  end
end

---@param cardUI superkanban.cardUI|nil
---@param listUI superkanban.ListUI|nil
---@param ctx superkanban.Ctx
---@param buf number
function actions._set_keymaps(cardUI, listUI, ctx, buf)
  for lhs, rhs in pairs(ctx.config.mappings) do
    local opts = { buffer = buf }

    if type(rhs) == 'string' then
      opts.desc = rhs
      local callback = actions[rhs]
      if not callback then
        return
      end

      vim.keymap.set('n', lhs, function()
        callback(cardUI, listUI, ctx)
      end, opts)
    elseif type(rhs) == 'table' then
      vim.keymap.set('n', lhs, function()
        rhs.callback(cardUI, listUI, ctx)
      end, utils.merge(opts, rhs))
    end
  end
end

return actions
