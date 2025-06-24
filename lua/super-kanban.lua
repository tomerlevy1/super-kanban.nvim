--- *super-kanban.txt* *super-kanban*

---@text TABLE OF CONTENTS
---
---@toc
---@tag super-kanban-table-of-contents
---@text

---@text 1. Introduction ~
---
--- super-kanban.nvim is a fast, minimal, and keyboard-centric Kanban board plugin
--- for Neovim. It’s fully customizable and supports both Obsidian Kanban-style
--- Markdown and Org-mode formats, allowing you to manage tasks
--- seamlessly within your Neovim workflow.
---@tag super-kanban-introduction
---@toc_entry 1. Introduction

---@text FEATURES
---
--- - Keyboard-centric Kanban workflow built for Neovim
--- - Treesitter-based parsing for `Markdown` and `Orgmode` (`neorg comming soon`)
--- - Compatible with obsidian-kanban style markdown
--- - Supports tags, checkmarks, due dates, and note links in cards
--- - Built-in date picker for assigning due dates and sorting or archiving cards
---@tag super-kanban-introduction-features
---@toc_entry   - Features

---@text 2. Installation ~
---@tag super-kanban-installation
---@toc_entry 2. Installation

---@text REQUIREMENTS
---
--- - snacks.nvim https://github.com/folke/snacks.nvim
--- - Treesitter parser for 'markdown' or 'org'
--- - Neovim version 0.8 or higher
---
---@text OPTIONAL REQUIREMENTS
---
--- - orgmode.nvim https://github.com/nvim-orgmode/orgmode (for Org file support)
--- - flash.nvim https://github.com/folke/flash.nvim       (for jump navigation)
---@tag super-kanban-installation-requirements
---@toc_entry   - Requirements

---@text lazy.nvim ~
--- >lua
---   {
---     "hasansujon786/super-kanban.nvim",
---     dependencies = {
---       "folke/snacks.nvim",           -- [required]
---       "nvim-orgmode/orgmode",        -- [optional] Org format support
---     },
---     opts = {}, -- optional: pass your config table here
---   }
--- <
---@tag super-kanban-installation-lazy.nvim
---@toc_entry   - lazy.nvim

---@text mini.deps ~
--- >lua
---   require("mini.deps").add({
---     source = "hasansujon786/super-kanban.nvim",
---     depends = {
---       { source = "folke/snacks.nvim" },       -- [required]
---       { source = "nvim-orgmode/orgmode" },    -- [optional] Org format support
---     },
---   })
--- <
---@tag super-kanban-installation-mini.deps
---@toc_entry   - mini.deps

local Board = require('super-kanban.ui.board')
local List = require('super-kanban.ui.list')
local Card = require('super-kanban.ui.card')
local utils = require('super-kanban.utils')
local writer = require('super-kanban.parser.writer')

---@private
---@class superkanban
local M = {}

-- stylua: ignore start
---@text 3. Configuration ~
---
--- Use `super-kanban.setup()` to configure the plugin and override default options.
---
---@usage >lua
---   require('super-kanban').setup() -- use default configuration
---   -- OR
---   require('super-kanban').setup({
---     -- your custom options here
---   })
--- <
---@seealso |super-kanban-config-defaults| for a full list of available options.
---@tag super-kanban-config
---@toc_entry 3. Configuration

---@text DEFAULT OPTIONS
---@tag super-kanban-config-defaults
---@eval return MiniDoc.afterlines_to_code(MiniDoc.current.eval_section)
---@class superkanban.Config
--minidoc_replace_start ---@class Navbuddy.config
--minidoc_replace_end
--minidoc_replace_start {
local default_config = {
--minidoc_replace_end
  markdown = {
    -- Absolute or relative path where markdown note files are stored
    notes_dir = './.notes/',
    -- Markdown heading level used for lists (e.g. h2)
    list_heading = 'h2',
    -- Mark inserted when a list is marked complete
    list_auto_complete_mark = '**Complete**',
    -- String used to separate sections in the file
    section_separators = '***',
    -- Heading title for archived tasks
    archive_heading = 'Archive',
    -- Initial section headings for new boards
    default_template = {
      '## Backlog\n',
      '## Todo\n',
      '## Work in progress\n',
      '## Completed\n',
      '**Complete**',
    },
    -- Lines inserted at the top of the file
    header = {
      '---',
      '',
      'kanban-plugin: basic',
      '',
      '---',
      '',
    },
    -- Lines inserted at the bottom of the file
    footer = {
      '',
      '%% kanban:settings',
      '```',
      '{"kanban-plugin":"basic"}',
      '```',
      '%%',
    },
  },
  org = {
    -- Absolute or relative path where org note files are stored
    notes_dir = './.notes/',
    -- Org heading level used for lists (e.g. h2)
    list_heading = 'h2',
    -- Mark inserted when a list is marked complete
    list_auto_complete_mark = '*Complete*',
    -- String used to separate sections in the file
    section_separators = '-----',
    -- Heading title for archived tasks
    archive_heading = 'Archive',
    -- Initial section headings for new boards
    default_template = {
      '** Backlog\n',
      '** Todo\n',
      '** Work in progress\n',
      '** Completed\n',
      '*Complete*',
    },
    -- Lines inserted at the top of the file
    header = {},
    -- Lines inserted at the bottom of the file
    footer = {},
  },
  card = {
    -- Card window width (0 = auto)
    width = 0,
    -- Card window height in lines
    height = 6,
    -- Z-index layering of the card window
    zindex = 7,
    -- Card border characters (table of 8 sides)
    border = { '', '', '', ' ', '▁', '▁', '▁', ' ' }, -- Only add border at bottom
    -- Additional window-local options for the card
    win_options = {
      wrap = true,
      -- spell = true, -- Uncomment this to enable spell checking
    },
  },
  list = {
    -- Width of the list window (columns)
    width = 32,
    -- Height of the list window (0–1 = % of screen height)
    height = 0.9,
    -- Z-index layering of the list window
    zindex = 6,
    -- List window border characters
    -- border = { '', '', '', '│', '┘', '─', '└', '│' }, -- bottom single
    border = { '', '', '', '│', '╯', '─', '╰', '│' }, -- bottom rounded
    -- border = "rounded",
    -- Additional window-local options for the list
    win_options = {},
  },
  board = {
    -- Width of the board window (0 = full width)
    width = 0,
    -- Height of the board window
    height = vim.o.lines - 2,
    -- Z-index layering of the board
    zindex = 5,
    -- Board border characters (empty or filled)
    border = { '', ' ', '', '', '', '', '', '' }, -- Only add empty space on top border
    -- Additional window-local options for the board
    win_options = {},
    -- Padding around board content (top, left)
    padding = { top = 1, left = 8 },
  },
  date_picker = {
    -- Z-index for the date picker popup
    zindex = 10,
    -- Border style for the date picker (e.g. 'rounded')
    border = 'rounded',
    -- Additional window-local options
    win_options = {},
    -- Start of the week ('Sunday' or 'Monday')
    first_day_of_week = 'Sunday',
  },
  note_popup = {
    -- Width of the note popup (0–1 = % of screen width)
    width = 0.6,
    -- Height of the note popup (0–1 = % of screen height)
    height = 0.7,
    -- Z-index layering of the popup
    zindex = 8,
    -- Border style for the note popup window
    border = 'rounded',
    -- Additional window-local options
    win_options = {},
  },
  icons = {
    -- Character for left edge of a list
    list_left_edge = '║',
    -- Character for right edge of a list
    list_right_edge = '║',
    -- Left decorative separator for elements
    left_sep = '',
    -- Right decorative separator for elements
    right_sep = '',
    -- Arrows
    arrow_left = '←',
    arrow_right = '→',
    arrow_up = '↑',
    arrow_down = '↓',
    -- Symbols for checkbox states in cards
    card_checkmarks = {
      ['empty_box'] = '☐',
      [' '] = ' ',
      ['x'] = '✔',
    },
  },
  mappings = {
    -- Close board window
    ['q'] = 'close',
    -- Log card info
    ['X'] = 'log_info',

    -- Create card at various positions
    ['gN'] = 'create_card_before',
    ['gn'] = 'create_card_after',
    ['gK'] = 'create_card_top',
    ['gJ'] = 'create_card_bottom',

    -- Delete or archive cards
    ['gD'] = 'delete_card',
    ['g<C-t>'] = 'archive_card',

    -- Toggle card checkbox
    ['<C-t>'] = 'toggle_complete',

    -- Sort cards
    ['g.'] = 'sort_by_due_descending',
    ['g,'] = 'sort_by_due_ascending',

    -- Search cards
    ['/'] = 'search_card',
    -- Open date picker
    ['zi'] = 'pick_date',
    -- Open card note
    ['<cr>'] = 'open_card_note',

    -- List management
    ['zN'] = 'create_list_at_begin',
    ['zn'] = 'create_list_at_end',
    ['zD'] = 'delete_list',
    ['zr'] = 'rename_list',

    -- Navigation between cards/lists
    ['<C-k>'] = 'jump_up',
    ['<C-j>'] = 'jump_down',
    ['<C-h>'] = 'jump_left',
    ['<C-l>'] = 'jump_right',
    ['gg'] = 'jump_top',
    ['G'] = 'jump_bottom',
    ['z0'] = 'jump_list_begin',
    ['z$'] = 'jump_list_end',

    -- Move cards/lists
    ['<A-k>'] = 'move_up',
    ['<A-j>'] = 'move_down',
    ['<A-h>'] = 'move_left',
    ['<A-l>'] = 'move_right',
    ['zh'] = 'move_list_left',
    ['zl'] = 'move_list_right',
  },
}
--minidoc_afterlines_end
-- stylua: ignore end

---@private
---@param config? superkanban.Config
function M.setup(config)
  if config ~= nil then
    default_config = vim.tbl_deep_extend('keep', config, default_config)
  end

  require('super-kanban.command').setup(default_config)
  require('super-kanban.ui').setup(default_config)
end

M.is_opned = false

---@private
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

  local parsed_data = require('super-kanban.parser').parse_file(source_path, filetype, default_config)

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

---@text 4. API
---
--- The following functions are provided by |super-kanban|.
---@tag super-kanban-api
---@toc_entry 4. API

--- Open super-kanban board.
---@param source_path string Absolute or relative path to the source_path
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

--- Scaffold a Kanban file with default template.
---@param source_path string Absolute or relative path to the file used to
--- create the Kanban board.
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

  local decorators = default_config[filetype]
  local default_template = decorators.default_template
  if type(default_template) ~= 'table' and #default_template < 1 then
    utils.msg(('Invalid configuration: `config.%s.default_template`'):format(filetype), 'error')
    return
  end

  local lines = {}
  vim.list_extend(lines, decorators.header)
  vim.list_extend(lines, default_template)
  vim.list_extend(lines, decorators.footer)

  local success = writer.write_lines(source_path, lines)
  if not success then
    return
  end

  M.open(source_path)
end

return M
