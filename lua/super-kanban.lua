local Board = require('super-kanban.ui.board')
local List = require('super-kanban.ui.list')
local Card = require('super-kanban.ui.card')
local utils = require('super-kanban.utils')
local writer = require('super-kanban.parser.writer')

---@class superkanban
local M = {}

---@class superkanban.Config
local config = {
  org = {
    description_folder = './tasks/',
    list_heading = 'h2',
    list_auto_complete_mark = '*Complete*',
    section_separators = '-----',
    archive_heading = 'Archive',
    default_template = {
      '** Backlog',
      '** Todo',
      '** Work in progress',
      '** Completed',
      '*Complete*',
    },
    header = {
      '---',
      '',
      'kanban-plugin: basic',
      '',
      '---',
      '',
    },
    footer = {
      '',
      '',
      '%% kanban:settings',
      '```',
      '{"kanban-plugin":"basic"}',
      '```',
      '%%',
    },
  },
  markdown = {
    description_folder = './tasks/',
    list_heading = 'h2',
    list_auto_complete_mark = '**Complete**',
    section_separators = '***',
    archive_heading = 'Archive',
    default_template = {
      '## Backlog',
      '## Todo',
      '## Work in progress',
      '## Completed',
      '**Complete**',
    },
    header = {
      '---',
      '',
      'kanban-plugin: basic',
      '',
      '---',
      '',
    },
    footer = {
      '',
      '',
      '%% kanban:settings',
      '```',
      '{"kanban-plugin":"basic"}',
      '```',
      '%%',
    },
  },
  card = {
    width = 0,
    height = 6,
    zindex = 7,
    border = { '', '', '', ' ', '▁', '▁', '▁', ' ' }, -- Only add border at bottom
    win_options = {
      wrap = true,
      -- spell = true, Uncomment this to enable spell checking
    },
  },
  list = {
    width = 32,
    height = 0.9,
    zindex = 6,
    -- border = { '', '', '', '│', '┘', '─', '└', '│' }, -- bottom single
    border = { '', '', '', '│', '╯', '─', '╰', '│' }, -- bottom rounded
    -- border = "rounded",
    win_options = {},
  },
  board = {
    width = 0,
    height = vim.o.lines - 2,
    zindex = 5,
    border = { '', ' ', '', '', '', '', '', '' }, -- Only add empty space on top border
    win_options = {},
    padding = { top = 1, left = 8 },
  },
  date_picker = {
    zindex = 10,
    border = 'rounded',
    win_options = {},
    first_day_of_week = 'Sunday',
  },
  note_popup = {
    width = 0.6,
    height = 0.7,
    zindex = 8,
    border = 'rounded',
    win_options = {},
  },
  icons = {
    list_left_edge = '║',
    list_right_edge = '║',
    left_sep = '',
    right_sep = '',
    arrow_left = '←',
    arrow_right = '→',
    arrow_up = '↑',
    arrow_down = '↓',
    card_checkmarks = {
      ['empty_box'] = '☐',
      [' '] = ' ',
      ['x'] = '✔',
    },
  },
  mappings = {
    ['q'] = 'close',
    ['/'] = 'search_card',
    ['zi'] = 'pick_date',
    ['X'] = 'log_info',

    ['<cr>'] = 'open_card_note',
    ['gn'] = 'create_card_at_begin',
    ['gN'] = 'create_card_at_end',
    ['gD'] = 'delete_card',
    ['g.'] = 'sort_by_due_descending',
    ['g,'] = 'sort_by_due_ascending',
    ['<C-t>'] = 'toggle_complete',
    ['g<C-t>'] = 'archive_card',

    ['zn'] = 'create_list_at_begin',
    ['zN'] = 'create_list_at_end',
    ['zD'] = 'delete_list',
    ['zr'] = 'rename_list',

    ['<C-k>'] = 'jump_up',
    ['<C-j>'] = 'jump_down',
    ['<C-h>'] = 'jump_left',
    ['<C-l>'] = 'jump_right',
    ['gg'] = 'jump_first',
    ['G'] = 'jump_last',

    ['<A-k>'] = 'move_up',
    ['<A-j>'] = 'move_down',
    ['<A-h>'] = 'move_left',
    ['<A-l>'] = 'move_right',

    ['z0'] = 'jump_list_first',
    ['z$'] = 'jump_list_last',
    ['zh'] = 'move_list_left',
    ['zl'] = 'move_list_right',
  },
}

M.is_opned = false

---@param source_path string
local function open_board(source_path)
  if not source_path or type(source_path) ~= 'string' or source_path == '' then
    utils.msg('Filename is missing. Please provide a valid file name.', 'warn')
    return
  end
  source_path = vim.fs.normalize(source_path)

  if not vim.uv.fs_stat(source_path) then
    utils.msg('File not found: [' .. source_path .. ']', 'warn')
    return nil
  end

  local filetype = utils.get_filetype_from_path(source_path)
  if not filetype then
    utils.msg('Unsupported file type: [' .. source_path .. '] Supported types: org & markdown', 'warn')
    return
  end

  local parsed_data = require('super-kanban.parser').parse_file(source_path, filetype, config)

  if not parsed_data or not parsed_data.lists or #parsed_data.lists == 0 then
    utils.msg('No list found in: [' .. source_path .. ']', 'warn')
    return
  end

  ---@type superkanban.Ctx
  local ctx = {}
  ctx.board = Board()
  ctx.source_path = source_path
  ctx.lists = {}
  ctx.archive = parsed_data.lists['archive']
  ctx.ft = filetype

  -- Setup list & card windows then generate ctx
  for list_index, list_data in ipairs(parsed_data.lists) do
    local list = List({
      data = { title = list_data.title },
      index = list_index,
      complete_task = list_data.complete_task,
      ctx = ctx,
    })

    ---@type superkanban.cardUI[]
    local cards = {}
    if type(list_data.tasks) == 'table' and #list_data.tasks ~= 0 then
      for task_index, task_data in ipairs(list_data.tasks) do
        cards[task_index] = Card({
          data = task_data,
          index = task_index,
          list_index = list_index,
          ctx = ctx,
        })
      end
    end

    ctx.lists[list_index] = List.generate_list_ctx(list, cards)
  end

  ctx.board:mount(ctx, {
    on_open = function()
      M.is_opned = true
    end,
    on_close = function()
      M.is_opned = false
    end,
  })

  M._ctx = ctx
end

---Open super-kanban
---@param source_path string
function M.open(source_path)
  if M.is_opned and M._ctx.source_path == source_path then
    return
  elseif M.is_opned and M._ctx.board then
    if M._ctx.board then
      M._ctx.board:exit()
    end

    vim.schedule(function()
      open_board(source_path)
    end)
    return
  end

  open_board(source_path)
end

---Scaffold a kanban file with default template
---@param source_path string
function M.create(source_path)
  if not source_path or type(source_path) ~= 'string' or source_path == '' then
    utils.msg('Filename is missing. Please provide a valid file name.', 'warn')
    return
  end
  source_path = vim.fs.normalize(source_path)

  if vim.uv.fs_stat(source_path) then
    utils.msg('File already exists: [' .. source_path .. ']', 'warn')
    return
  end

  local filetype = utils.get_filetype_from_path(source_path)
  if not filetype then
    utils.msg('Unsupported file type: [' .. source_path .. '] Supported types: org & markdown', 'warn')
    return
  end

  local default_template = config[filetype].default_template
  if type(default_template) ~= 'table' and #default_template < 1 then
    utils.msg(('Invalid configuration: `config.%s.default_template`'):format(filetype), 'error')
    return
  end

  local success = writer.write_lines(source_path, default_template)
  if not success then
    return
  end

  M.open(source_path)
end

---@param user_conf superkanban.Config
function M.setup(user_conf)
  if user_conf ~= nil then
    config = vim.tbl_deep_extend('keep', user_conf, config)
  end

  require('super-kanban.highlights').setup()
  require('super-kanban.user_command').setup(M, config)
  require('super-kanban.ui').setup(config)
end

-- lua require("super-kanban").open("test.md")

return M
