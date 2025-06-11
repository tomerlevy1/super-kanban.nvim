local actions = {}

actions.close = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    ctx.board:exit()
  end

  return { callback = callback, desc = 'Close SuperKanban' }
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
actions.create_card_at_begin = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _create_card(cardUI, listUI, ctx, 'first')
  end

  return { callback = callback, desc = 'Create a new card at the begin of the list' }
end
actions.create_card_at_end = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _create_card(cardUI, listUI, ctx, 'last')
  end

  return { callback = callback, desc = 'Create a new card at the end of the list' }
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

  return { callback = callback, desc = 'Delete card' }
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

  return { callback = callback, desc = 'Toggle Complete' }
end
actions.archive_card = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    if not cardUI then
      return
    end
    cardUI:move_to_archive()
  end

  return { callback = callback, desc = 'Archive card' }
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
actions.create_list_at_begin = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _create_list(cardUI, listUI, ctx, 'first')
  end

  return { callback = callback, desc = 'Create list at the begin of the board' }
end
actions.create_list_at_end = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _create_list(cardUI, listUI, ctx, 'last')
  end

  return { callback = callback, desc = 'Create list at end of the board' }
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

  return { callback = callback, desc = 'Delete list' }
end
actions.rename_list = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
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

  return { callback = callback, desc = 'Rename list' }
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
actions.sort_by_due_descending = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _sort_by_due(cardUI, listUI, ctx, 'newest_first')
  end

  return { callback = callback, desc = 'Sort cards in descending order' }
end
actions.sort_by_due_ascending = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _sort_by_due(cardUI, listUI, ctx, 'oldest_first')
  end

  return { callback = callback, desc = 'Sort cards in ascefnding order' }
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

  return { callback = callback, desc = 'Pick date' }
end
actions.remove_date = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    if not cardUI then
      return
    end
    cardUI:remove_date()
  end

  return { callback = callback, desc = 'Remove date' }
end

actions.log_info = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
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

  return { callback = callback, desc = 'Print card info' }
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
actions.move_left = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _move(cardUI, 'left')
  end

  return { callback = callback, desc = 'Move card to left' }
end
actions.move_right = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _move(cardUI, 'right')
  end

  return { callback = callback, desc = 'Move card to right' }
end
actions.move_up = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _move(cardUI, 'up')
  end

  return { callback = callback, desc = 'Move card to up' }
end
actions.move_down = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _move(cardUI, 'down')
  end

  return { callback = callback, desc = 'Move card to down' }
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
actions.move_list_left = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _move_list(cardUI, listUI, ctx, 'left')
  end

  return { callback = callback, desc = 'Move list to left' }
end
actions.move_list_right = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _move_list(cardUI, listUI, ctx, 'right')
  end

  return { callback = callback, desc = 'Move list to right' }
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
actions.jump_left = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump(cardUI, listUI, ctx, 'left')
  end

  return { callback = callback, desc = 'Jump to left card' }
end
actions.jump_right = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump(cardUI, listUI, ctx, 'right')
  end

  return { callback = callback, desc = 'Jump to right card' }
end
actions.jump_up = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump(cardUI, listUI, ctx, 'up')
  end

  return { callback = callback, desc = 'Jump to up card' }
end
actions.jump_down = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump(cardUI, listUI, ctx, 'down')
  end

  return { callback = callback, desc = 'Jump to down card' }
end
actions.jump_first = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump(cardUI, listUI, ctx, 'first')
  end

  return { callback = callback, desc = 'Jump to first card' }
end
actions.jump_last = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump(cardUI, listUI, ctx, 'last')
  end

  return { callback = callback, desc = 'Jump to last card' }
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
actions.jump_list_left = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump_list(cardUI, listUI, ctx, 'left')
  end

  return { callback = callback, desc = 'Jump to left list' }
end
actions.jump_list_right = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump_list(cardUI, listUI, ctx, 'right')
  end

  return { callback = callback, desc = 'Jump to right list' }
end
actions.jump_list_first = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump_list(cardUI, listUI, ctx, 'first')
  end

  return { callback = callback, desc = 'Jump to first list' }
end
actions.jump_list_last = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    _jump_list(cardUI, listUI, ctx, 'last')
  end

  return { callback = callback, desc = 'Jump to last list' }
end

actions.search = function()
  ---@param cardUI superkanban.cardUI|nil
  ---@param listUI superkanban.ListUI|nil
  ---@param ctx superkanban.Ctx
  local callback = function(cardUI, listUI, ctx)
    require('super-kanban.pickers.snacks').search_cards({}, ctx, cardUI or listUI)
  end

  return { callback = callback, desc = 'Search', nowait = true }
end

return actions
