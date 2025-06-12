local Board = require('super-kanban.ui.board')
local List = require('super-kanban.ui.list')
local Card = require('super-kanban.ui.card')
local actions = require('super-kanban.actions')
local utils = require('super-kanban.utils')

---@class superkanban
local M = {}

---@class superkanban.Config
---@field markdown superkanban.MarkdownConfig
local config = {
  markdown = {
    description_folder = './tasks/', -- "./"
    list_head = 'h2',
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
    border = { '', '', '', ' ', '▁', '▁', '▁', ' ' }, -- add border at bottom
    win_options = {
      wrap = true,
      -- spell = true, Uncomment this to enable spell checking
    },
  },
  list = {
    width = 32,
    height = 0.9,
    zindex = 6,
    -- border = { "", "", "", "│", "┘", "─", "└", "│" }, -- bottom single
    border = { '', '', '', '│', '╯', '─', '╰', '│' }, -- bottom rounded
    -- border = "rounded",
    win_options = {},
  },
  board = {
    width = 0,
    height = vim.o.lines - 2,
    zindex = 5,
    border = { '', ' ', '', '', '', '', '', '' }, -- add empty space on top border
    win_options = {},
    padding = { top = 1, left = 8 },
  },
  date_picker = {
    zindex = 10,
    border = 'rounded',
    win_options = {},
    first_day_of_week = 'Sunday',
  },
  icons = {
    card_checkmarks = {
      ['empty_box'] = '☐',
      [' '] = ' ',
      ['x'] = '✔',
    },
  },
  mappings = {
    ['gn'] = actions.create_card_at_begin(),
    ['gN'] = actions.create_card_at_end(),
    ['gD'] = actions.delete_card(),
    ['g.'] = actions.sort_by_due_descending(),
    ['g,'] = actions.sort_by_due_ascending(),
    ['<C-t>'] = actions.toggle_complete(),
    ['g<C-t>'] = actions.archive_card(),

    ['zn'] = actions.create_list_at_begin(), -- wrong
    ['zN'] = actions.create_list_at_end(),
    ['zD'] = actions.delete_list(),
    ['zr'] = actions.rename_list(),

    ['<C-k>'] = actions.jump_up(),
    ['<C-j>'] = actions.jump_down(),
    ['<C-h>'] = actions.jump_left(),
    ['<C-l>'] = actions.jump_right(),
    ['gg'] = actions.jump_first(),
    ['G'] = actions.jump_last(),

    ['<A-k>'] = actions.move_up(),
    ['<A-j>'] = actions.move_down(),
    ['<A-h>'] = actions.move_left(),
    ['<A-l>'] = actions.move_right(),

    ['z0'] = actions.jump_list_first(),
    ['z$'] = actions.jump_list_last(),
    ['zh'] = actions.move_list_left(),
    ['zl'] = actions.move_list_right(),

    ['q'] = actions.close(),
    ['/'] = actions.search(),
    ['zi'] = actions.pick_date(),
    ['X'] = actions.log_info(),
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

  local is_markdown = utils.is_markdown(source_path)
  local is_org = utils.is_org(source_path)

  if not (is_markdown or is_org) then
    utils.msg('Unsupported file type: [' .. source_path .. '] Supported types: org & markdown', 'warn')
    return
  end

  local filetype = is_markdown and 'markdown' or is_org and 'org'
  local parsed_data = require('super-kanban.parser').parse_file(source_path, filetype)

  if not parsed_data or not parsed_data.lists or #parsed_data.lists == 0 then
    utils.msg('No list found in: [' .. source_path .. ']', 'warn')
    return
  end

  ---@type superkanban.Ctx
  local ctx = {}
  ctx.board = Board()
  ctx.config = config
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

  if not utils.is_markdown(source_path) then
    utils.msg('Unsupported file type: [' .. source_path .. '] Supported types: .md', 'warn')
    return
  end
  if vim.uv.fs_stat(source_path) then
    utils.msg('File already exists: [' .. source_path .. ']', 'warn')
    return
  end

  local file = io.open(source_path, 'w')
  if not file then
    utils.msg('Failed to create file: [' .. source_path .. ']', 'error')
    return
  end
  if type(config.markdown.default_template) ~= 'table' and #config.markdown.default_template < 1 then
    utils.msg('Invalid configuration: `config.markdown.default_template`', 'error')
    return
  end

  for _, line in pairs(config.markdown.default_template) do
    file:write(line .. '\n')
  end

  file:close()
  utils.msg('Created file: [' .. source_path .. '].', 'info')
  M.open(source_path)
end

function M.setup(user_conf)
  if user_conf ~= nil then
    config = vim.tbl_deep_extend('keep', user_conf, config)
  end

  require('super-kanban.highlights').setup_highlights()
  require('super-kanban.user_command').setup_commands(M, config)
end

-- lua require("super-kanban").open("test.md")

return M
