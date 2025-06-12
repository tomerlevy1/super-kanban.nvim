local M = {}

function M.get_default(x, default)
  M.if_nil(x, default, x)
end

function M.if_nil(x, was_nil, was_not_nil)
  if x == nil then
    return was_nil
  else
    return was_not_nil
  end
end

---@param msg string
---@param level? "trace"|"debug"|"info"|"warn"|"error"
function M.msg(msg, level)
  vim.notify(msg, level, { title = 'SuperKanban' })
end

function M.is_cursor_at_last_column(col)
  local line = vim.api.nvim_get_current_line()
  return col >= #line
end

function M.merge(default, override)
  if not override then
    return default
  end
  return vim.tbl_extend('force', default, override)
end

-- _G.on_winbar_click = function(minwid, clicks, button, mods)
-- 	vim.notify("Clicked winbar! Button: " .. button, vim.log.levels.INFO)
-- end
function M.with_click(text, lua_fn_name, arg)
  arg = arg and arg or 0
  return string.format('%%%s@v:lua.%s@%s%%X', arg, lua_fn_name, text)
end
function M.with_hl(text, hl)
  return string.format('%%#%s#%s', hl, text)
end

function M.is_markdown(path)
  return path:match('%.md$') or path:match('%.markdown$')
end

function M.is_org(path)
  return path:match('%.org$')
end

return M
