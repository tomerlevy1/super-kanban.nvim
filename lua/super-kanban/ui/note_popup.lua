local hl = require('super-kanban.highlights')
local utils = require('super-kanban.utils')
local writer = require('super-kanban.parser.writer')

---@type superkanban.Config
local config

---@class superkanban.NotePopup.NewOpts
---@field data {title:string,file_path:string}
---@field on_close fun()

---@class superkanban.NotePopupUI
---@field data {title:string,file_path:string}
---@field win snacks.win
---@field ctx superkanban.Ctx
---@field type 'note_popup'
---@overload fun(opts?:superkanban.NotePopup.NewOpts,ctx:superkanban.Ctx): superkanban.NotePopupUI
local M = setmetatable({}, {
  __call = function(t, ...)
    return t.new(...)
  end,
})
M.__index = M

---@param opts superkanban.NotePopup.NewOpts
---@param ctx superkanban.Ctx
---@return superkanban.NotePopupUI
function M.new(opts, ctx)
  ---@diagnostic disable-next-line: param-type-mismatch
  local self = setmetatable({}, M)

  self.data = opts.data
  self.ctx = ctx
  self.type = 'note_popup'

  self.win = self:setup_win(opts)

  return self
end

---@param lines string[]
---@param ft superkanban.ft
function M.create_note_and_get_path(lines, ft)
  local line = vim.trim(lines[1])
  if #lines == 0 or not line or line == '' then
    utils.msg('No name found', 'warn')
    return false
  end

  -- Extract link title from first line
  local new_link = false
  local link_title = line:match('%[%[(.-)%]%]')
  if not link_title then
    link_title = line
    new_link = true
  end
  link_title = vim.trim(link_title)

  if not link_title or link_title == '' then
    utils.msg('No name found', 'warn')
    return false
  end

  local dir = config[ft].description_folder
  local file_path = vim.fs.normalize(dir .. '/' .. link_title .. '.md')

  -- Create a new dir if not exists
  if not vim.uv.fs_stat(dir) then
    pcall(vim.fn.mkdir, dir)
  end

  -- Create a new file if not exists
  if not vim.uv.fs_stat(file_path) then
    local success = writer.write_lines(file_path, { '# ' .. link_title })
    if not success then
      return false
    end
  end

  return file_path, link_title, new_link
end

---@param opts superkanban.NotePopup.NewOpts
---@return snacks.win
function M:setup_win(opts)
  local icons = config.icons
  local fname_tail = vim.fn.fnamemodify(opts.data.file_path, ':t')
  local title = {
    { icons.left_sep, 'SuperKanbanNoteTitleEdge' },
    { fname_tail, 'SuperKanbanNoteTitle' },
    { icons.right_sep, 'SuperKanbanNoteTitleEdge' },
  }

  local note_conf = config.note_popup

  return Snacks.win({
    -- User config values
    width = note_conf.width,
    height = note_conf.height,
    border = note_conf.border,
    zindex = note_conf.zindex,
    footer = title,
    footer_pos = 'center',
    -- title = title,
    -- title_pos = 'center',
    wo = utils.merge({
      winhighlight = hl.note_popup,
    }, note_conf.win_options),
    -- Non config values
    backdrop = false,
    file = opts.data.file_path,
    on_win = function()
      vim.schedule(function()
        self:set_events(opts)
      end)
    end,
    bo = {
      modifiable = true,
    },
  })
end

---@param opts superkanban.NotePopup.NewOpts
function M:set_events(opts)
  self.win:on({ 'WinClosed' }, function()
    local buf = self.win.buf
    if not buf then
      return
    end

    utils.save_buffer(buf)
    vim.schedule(function()
      opts.on_close()
      pcall(vim.api.nvim_buf_delete, buf, { force = true })
    end)
  end, { buf = true, once = true })
end

---@param conf superkanban.Config
function M.setup(conf)
  config = conf
end

return M
