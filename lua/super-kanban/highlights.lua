local c = {
  none = 'NONE',
  bg0 = '#242b38',
  bg1 = '#2d3343',
  bg2 = '#343e4f',
  bg3 = '#363c51',
  bg_d = '#1e242e',
  bg_d2 = '#1b222c',
  black = '#151820',

  fg = '#abb2bf',
  light_grey = '#8b95a7',
  grey = '#546178',
  white = '#dfdfdf',
  muted = '#68707E',
  layer = '#3E425D',

  red = '#ef5f6b',
  green = '#97ca72',
  orange = '#d99a5e',
  yellow = '#ebc275',
  blue = '#5ab0f6',
  purple = '#ca72e4',
  cyan = '#4dbdcb',

  diff_add = '#303d27',
  diff_change = '#18344c',
  diff_delete = '#3c2729',
  diff_text = '#265478',

  bg_yellow = '#f0d197',
  bg_blue = '#6db9f7',

  dim_red = '#4D3542',
  dim_green = '#3B4048',
  dim_yellow = '#4C4944',
  dim_blue = '#204364',
  dim_purple = '#45395A',
  dim_cyan = '#2C4855',

  -- #777700
  dark_purple = '#8f36a9',
  dark_red = '#a13131',
  dark_orange = '#9a6b16',
  dark_blue = '#127ace',
  dark_green = '#5e9437',
  dark_cyan = '#25747d',

  ligh_green = '#00a86d',
}

local winhighlight = function(highlight)
  return table.concat(
    vim.tbl_map(function(key)
      return key .. ':' .. highlight[key]
    end, vim.tbl_keys(highlight)),
    ','
  )
end

local M = {
  board = winhighlight({
    Normal = 'SuperKanbanBoardNormal',
    NormalNC = 'SuperKanbanBoardNormal',
    WinBar = 'SuperKanbanBoardWinbar',
    WinBarNC = 'SuperKanbanBoardWinbar',
  }),
  list = winhighlight({
    Normal = 'SuperKanbanListNormal',
    NormalNC = 'SuperKanbanListNormal',
    WinBar = 'SuperKanbanListWinbar',
    WinBarNC = 'SuperKanbanListWinbar',
    FloatBorder = 'SuperKanbanListBorder',
    FloatTitle = 'SuperKanbanListTitleBottom',
  }),
  card = winhighlight({
    Normal = 'SuperKanbanCardNormal',
    NormalNC = 'SuperKanbanCardNormalNC',
    WinBar = 'SuperKanbanCardWinbar',
    WinBarNC = 'SuperKanbanCardWinbarNC',
    FloatBorder = 'SuperKanbanCardSeparatorNC',
  }),
  cardActive = winhighlight({
    Normal = 'SuperKanbanCardNormal',
    NormalNC = 'SuperKanbanCardNormalNC',
    WinBar = 'SuperKanbanCardWinbar',
    WinBarNC = 'SuperKanbanCardWinbarNC',
    FloatBorder = 'SuperKanbanCardSeparator',
  }),
  date_picker = winhighlight({
    Normal = 'SuperKanbanDatePickerNormal',
    NormalNC = 'SuperKanbanDatePickerNormal',
    FloatBorder = 'SuperKanbanDatePickerBorder',
    Title = 'SuperKanbanDatePickerTitle',
  }),
  note_popup = winhighlight({
    Normal = 'SuperKanbanNoteNormal',
    NormalNC = 'SuperKanbanNoteNormalNC',
    FloatBorder = 'SuperKanbanNoteBorder',
  }),
}

function M.setup()
  local float_bg = '#21252B'
  local border_fg = c.cyan
  -- stylua: ignore
  local highlights = {
    SuperKanbanBoardNormal           = { fg = c.fg, bg = c.none },
    SuperKanbanBoardWinbar           = { link = 'SuperKanbanBoardNormal' },
    SuperKanbanBoardTitle            = { fg = c.bg0, bg = c.orange },
    SuperKanbanBoardTitleEdge        = { fg = c.orange, bg = c.none },
    SuperKanbanBoardScrollInfo       = { fg = c.bg0, bg = c.cyan },
    SuperKanbanBoardScrollInfoEdge   = { fg = c.cyan, bg = c.none },
    SuperKanbanBoardToolbar          = { fg = c.light_grey, bg = c.none },

    -- List window
    SuperKanbanListNormal            = { link = 'SuperKanbanBoardNormal' },
    SuperKanbanListBorder            = { fg = border_fg, bg = c.none },
    SuperKanbanListWinbar            = { fg = c.bg0, bg = border_fg },
    SuperKanbanListTitleBottom       = { fg = c.green, bg = c.none },

    -- Card window
    SuperKanbanCardNormal            = { fg = c.fg, bg = float_bg },
    SuperKanbanCardWinBar            = { fg = c.light_grey, bg = float_bg },
    SuperKanbanCardSeparator         = { fg = border_fg, bg = float_bg },
    SuperKanbanCardNormalNC          = { fg = c.fg, bg = c.none },
    SuperKanbanCardWinbarNC          = { fg = c.grey, bg = c.none },
    SuperKanbanCardSeparatorNC       = { fg = border_fg, bg = c.none },

    -- Card content
    SuperKanbanNone                  = { fg = c.none, bg = c.none },
    SuperKanbanTag                   = { fg = c.yellow, bg = c.dim_yellow },
    SuperKanbanDueDate               = { fg = '#8a5cf5' },
    SuperKanbanCheckMark             = { link = 'SuperKanbanCardWinbarNC' },
    SuperKanbanCheckMarkDone         = { fg = c.dark_green },
    SuperKanbanLink                  = { link = 'Function' },
    SuperKanbanLinkDelimiter         = { link = 'SuperKanbanLink'  },

    -- NotePopup window
    SuperKanbanNoteNormal            = { fg = c.fg, bg = float_bg },
    SuperKanbanNoteNormalNC          = { link = 'NormalNC' },
    SuperKanbanNoteBorder            = { fg = border_fg, bg = c.none },
    SuperKanbanNoteTitle             = { link = 'SuperKanbanBoardScrollInfo' },
    SuperKanbanNoteTitleEdge         = { link = 'SuperKanbanBoardScrollInfoEdge' },

    -- Date Picker window
    SuperKanbanDatePickerToday       = { fg = c.green },
    SuperKanbanDatePickerCursor      = { fg = c.bg_d, bg = c.blue },
    SuperKanbanDatePickerNormal      = { link = 'SuperKanbanBoardNormal' },
    SuperKanbanDatePickerBorder      = { link = 'FloatBorder' },
    SuperKanbanDatePickerTitle       = { link = 'Title' },
    SuperKanbanDatePickerWeekDays    = { fg = c.green, italic = true },
    SuperKanbanDatePickerSeparator   = { link = 'Comment' },
  }

  for hl_name, option in pairs(highlights) do
    vim.api.nvim_set_hl(0, hl_name, option)
  end
end

---@param text string
---@param opts {left_sep:string,right_sep:string,text_hl:string,sep_hl:string}
---@return string
function M.build_str_with_separator(text, opts)
  return table.concat({
    opts.sep_hl,
    opts.left_sep,
    opts.text_hl,
    text,
    opts.sep_hl,
    opts.right_sep,
  })
end

return M
