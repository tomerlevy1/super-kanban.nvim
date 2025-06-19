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

-- %#KanbanBoardTitle#
local make_winhighlight = function(highlight)
  return table.concat(
    vim.tbl_map(function(key)
      return key .. ':' .. highlight[key]
    end, vim.tbl_keys(highlight)),
    ','
  )
end

local M = {
  board = make_winhighlight({
    Normal = 'KanbanNormal',
    NormalNC = 'KanbanNormal',
  }),
  list = make_winhighlight({
    Normal = 'KanbanListNormal',
    NormalNC = 'KanbanListNormal',
    WinBar = 'KanbanListWinbar',
    WinBarNC = 'KanbanListWinbar',
    FloatBorder = 'KanbanListBorder',
    FloatTitle = 'KanbanListTitleBottom',
  }),
  card = make_winhighlight({
    Normal = 'KanbanCardNormal',
    NormalNC = 'KanbanCardNormalNC',
    WinBar = 'KanbanCardWinbar',
    WinBarNC = 'KanbanCardWinbarNC',
    FloatBorder = 'KanbanCardSeparatorNC',
  }),
  cardActive = make_winhighlight({
    Normal = 'KanbanCardNormal',
    NormalNC = 'KanbanCardNormalNC',
    WinBar = 'KanbanCardWinbar',
    WinBarNC = 'KanbanCardWinbarNC',
    FloatBorder = 'KanbanCardSeparator',
  }),
  date_picker = make_winhighlight({
    Normal = 'KanbanDatePickerNormal',
    NormalNC = 'KanbanDatePickerNormal',
    FloatBorder = 'KanbanDatePickerBorder',
    Title = 'KanbanDatePickerTitle',
  }),
  note_popup = make_winhighlight({
    Normal = 'KanbanNoteNormal',
    NormalNC = 'KanbanNoteNormalNC',
    FloatBorder = 'KanbanNoteBorder',
  }),
}

function M.setup()
  local float_bg = '#21252B'
  local border_fg = c.cyan
  -- stylua: ignore
  local highlights = {
    KanbanNormal                = { fg = c.fg, bg = c.none },
    KanbanWinbar                = { link = 'KanbanNormal' },

    KanbanBoardTitle            = { fg = c.bg0, bg = c.orange },
    KanbanBoardTitleEdge        = { fg = c.orange, bg = c.bg0 },
    KanbanBoardScrollInfo       = { fg = c.bg0, bg = c.cyan },
    KanbanBoardScrollInfoEdge   = { fg = c.cyan, bg = c.none },
    KanbanBoardToolbar          = { fg = c.light_grey, bg = c.none },

    -- List window
    KanbanListNormal            = { link = 'KanbanNormal' },
    KanbanListBorder            = { fg = border_fg, bg = c.none },
    KanbanListWinbar            = { fg = c.bg0, bg = border_fg },
    KanbanListTitleBottom       = { fg = c.green, bg = c.none },

    -- Card window
    KanbanCardNormal            = { fg = c.fg, bg = float_bg },
    KanbanCardWinBar            = { fg = c.light_grey, bg = float_bg },
    KanbanCardSeparator         = { fg = border_fg, bg = float_bg },
    KanbanCardNormalNC          = { fg = c.fg, bg = c.none },
    KanbanCardWinbarNC          = { fg = c.grey, bg = c.none },
    KanbanCardSeparatorNC       = { fg = border_fg, bg = c.none },

    -- NotePopup window
    KanbanNoteNormal            = { fg = c.fg, bg = float_bg },
    KanbanNoteNormalNC          = { link = 'NormalNC' },
    KanbanNoteBorder            = { fg = border_fg, bg = c.none },

    -- Card cotent
    KanbanNone                  = { fg = c.none, bg = c.none },
    KanbanTag                   = { fg = c.yellow, bg = c.dim_yellow },
    KanbanDueDate               = { fg = '#8a5cf5' },
    KanbanCheckMark             = { link = 'KanbanCardWinbarNC' },
    KanbanCheckMarkDone         = { fg = c.dark_green },

    -- Date Picker window
    KanbanDatePickerDateToday   = { fg = c.green },
    KanbanDatePickerUnderCursor = { fg = c.bg_d, bg = c.blue },
    KanbanDatePickerNormal      = { link = 'KanbanNormal' },
    KanbanDatePickerBorder      = { link = 'FloatBorder' },
    KanbanDatePickerTitle       = { link = 'Title' },
    KanbanDatePickerWeekDays    = { fg = c.green, italic = true },
    KanbanDatePickerSeparator   = { link = 'Comment' },
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
