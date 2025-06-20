local prefix = 'SuperKanban'

local winhighlight = function(highlights)
  return table.concat(
    vim.tbl_map(function(key)
      return key .. ':' .. prefix .. highlights[key]
    end, vim.tbl_keys(highlights)),
    ','
  )
end

local M = {
  board = winhighlight({
    Normal = 'BoardNormal',
    NormalNC = 'BoardNormal',
    WinBar = 'BoardWinbar',
    WinBarNC = 'BoardWinbar',
    FloatBorder = 'BoardBorder',
  }),
  list = winhighlight({
    Normal = 'ListNormal',
    NormalNC = 'ListNormal',
    WinBar = 'ListWinbar',
    WinBarNC = 'ListWinbar',
    FloatBorder = 'ListBorder',
    FloatTitle = 'ListTitleBottom',
  }),
  card = winhighlight({
    Normal = 'CardNormal',
    NormalNC = 'CardNormalNC',
    WinBar = 'CardWinbar',
    WinBarNC = 'CardWinbarNC',
    FloatBorder = 'CardBorderNC',
  }),
  cardActive = winhighlight({
    Normal = 'CardNormal',
    NormalNC = 'CardNormalNC',
    WinBar = 'CardWinbar',
    WinBarNC = 'CardWinbarNC',
    FloatBorder = 'CardBorder', -- FloatBorder doesn't have NC concept so update it manually
  }),
  date_picker = winhighlight({
    Normal = 'DatePickerNormal',
    NormalNC = 'DatePickerNormal',
    FloatBorder = 'DatePickerBorder',
    Title = 'DatePickerTitle',
  }),
  note_popup = winhighlight({
    Normal = 'NoteNormal',
    NormalNC = 'NoteNormalNC',
    FloatBorder = 'NoteBorder',
  }),
}

function M.setup()
  local darker_bg = '#21252B'
  local constant_fg = require('super-kanban.utils.hl').get_hl('Constant')
  local border_fg = require('super-kanban.utils.hl').get_hl('FloatBorder')
  local _, cursor_bg = require('super-kanban.utils.hl').get_hl('Cursor')

  -- stylua: ignore
  require('super-kanban.utils.hl').set_hl({
    Normal                = 'NormalFloat',
    Winbar                = 'SuperKanbanNormal' ,
    Border                = 'FloatBorder',
    Pill                  = { fg = darker_bg, bg = border_fg },
    PillEdge              = 'FloatBorder',

    BoardNormal           = 'SuperKanbanNormal',
    BoardBorder           = 'SuperKanbanBorder',
    BoardWinbar           = 'SuperKanbanWinbar',
    BoardFileName         = { fg = darker_bg, bg = constant_fg },
    BoardFileNameEdge     = { fg = constant_fg },
    BoardScrollInfo       = 'SuperKanbanPill',
    BoardScrollInfoEdge   = 'SuperKanbanPillEdge',

    -- List window
    ListNormal            = 'SuperKanbanNormal',
    ListBorder            = 'SuperKanbanBorder',
    ListWinbar            = 'SuperKanbanPill', -- it is revers of ListBorder
    ListTitleBottom       = 'String',

    -- Card window
    CardNormal            = { bg = darker_bg }, -- Use darker color use to show active card
    CardNormalNC          = 'SuperKanbanNormal',
    CardBorder            = { fg = border_fg, bg = darker_bg }, -- Use darker color use to show active card
    CardBorderNC          = 'SuperKanbanBorder',
    CardWinBar            = 'SuperKanbanCardNormal',
    CardWinbarNC          = 'LineNr',

    -- Card content
    None                  = { fg = 'NONE' },
    Tag                   = { fg = constant_fg, bg = '#4C4944' },
    DueDate               = 'Keyword',
    CheckMark             = 'SuperKanbanNone',
    CheckMarkDone         = 'String',
    Link                  = 'Function' ,
    LinkDelimiter         = '@punctuation.bracket',

    -- Note window
    NoteNormal            = 'SuperKanbanNormal',
    NoteNormalNC          = 'SuperKanbanNoteNormal',
    NoteBorder            = 'SuperKanbanBorder',
    NoteTitle             = 'SuperKanbanPill' ,
    NoteTitleEdge         = 'SuperKanbanPillEdge' ,

    -- Date Picker window
    DatePickerNormal      = 'SuperKanbanNormal' ,
    DatePickerBorder      = 'SuperKanbanBorder',
    DatePickerTitle       = 'Type' ,
    DatePickerWeekDays    = 'SuperKanbanBorder',
    DatePickerSeparator   = 'NonText',
    DatePickerToday       = 'SuperKanbanTag',
    DatePickerCursor      = { fg = darker_bg,  bg = cursor_bg },
  }, { prefix = prefix, default = false })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('superkanban_hl', { clear = true }),
  callback = function()
    M.setup()
  end,
})

return M
