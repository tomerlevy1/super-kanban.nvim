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
  mappings = {
    ['gn'] = actions.create_card('first'),
    ['gN'] = actions.create_card('last'),
    ['gD'] = actions.delete_card(),
    ['g.'] = actions.sort_cards_by_due('oldest_first'),
    ['g,'] = actions.sort_cards_by_due('newest_first'),

    ['zn'] = actions.create_list('last'),
    ['zN'] = actions.create_list('first'),
    ['zD'] = actions.delete_list(),
    ['zr'] = actions.rename_list(),

    ['<C-k>'] = actions.jump('up'),
    ['<C-j>'] = actions.jump('down'),
    ['<C-h>'] = actions.jump('left'),
    ['<C-l>'] = actions.jump('right'),
    ['gg'] = actions.jump('first'),
    ['G'] = actions.jump('last'),

    ['<A-k>'] = actions.move('up'),
    ['<A-j>'] = actions.move('down'),
    ['<A-h>'] = actions.move('left'),
    ['<A-l>'] = actions.move('right'),

    ['z0'] = actions.jump_list('first'),
    ['z$'] = actions.jump_list('last'),
    ['zh'] = actions.move_list('left'),
    ['zl'] = actions.move_list('right'),

    ['q'] = actions.close(),
    ['/'] = actions.search(),
    ['zi'] = actions.pick_date(),
    ['X'] = actions.log_info(),
  },
}

M.is_opned = false
---@type superkanban.Ctx
local ctx = {}

---@param source_path string
local function open_board(source_path)
  if not source_path or type(source_path) ~= 'string' or source_path == '' then
    utils.msg('Filename is missing. Please provide a valid file name.', 'warn')
    return
  end
  if not utils.is_markdown(source_path) then
    utils.msg('Unsupported file type: [' .. source_path .. '] Supported types: .md', 'warn')
    return
  end
  if not vim.uv.fs_stat(source_path) then
    utils.msg('File not found: [' .. source_path .. ']', 'warn')
    return nil
  end

  ctx.board = Board()
  ctx.config = config
  ctx.source_path = source_path
  ctx.lists = {}

  local first_card_loc = nil

  local parsed_data = require('super-kanban.parser.markdown').parse_file(source_path)

  -- Setup list & card windows then generate ctx
  for list_index, list_data in ipairs(parsed_data and parsed_data.lists or {}) do
    local list = List({
      data = { title = list_data.title },
      index = list_index,
      ctx = ctx,
    })

    ---@type superkanban.cardUI[]
    local cards = {}
    if type(list_data.tasks) == 'table' and #list_data.tasks ~= 0 then
      for task_index, task_data in ipairs(list_data.tasks) do
        if first_card_loc == nil then
          first_card_loc = { list_index, task_index }
        end
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
end

---Open super-kanban
---@param source_path string
function M.open(source_path)
  if M.is_opned and ctx.source_path == source_path then
    return
  elseif M.is_opned and ctx.board then
    if ctx.board then
      ctx.board:exit()
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
