local constants = require('super-kanban.constants')

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

---@param path any
---@return string|nil
function M.get_filetype_from_path(path)
  if M.is_markdown(path) then
    return 'markdown'
  end

  if M.is_org(path) then
    return 'org'
  end

  return nil
end

---@param head string
---@param ft superkanban.ft
function M.get_heading_prefix(head, ft)
  return constants[ft].headings[head] or constants[ft].headings.h2
end

---@param buf number
function M.save_buffer(buf)
  -- Check buffer validity before saving
  if buf > 0 and vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].modifiable then
    -- Save only if the buffer has a file name
    if vim.api.nvim_buf_get_name(buf) ~= '' then
      vim.api.nvim_buf_call(buf, function()
        vim.cmd('silent! write')
        return true
      end)
    end
  end

  return false
end

return M
