---@text 7. Highlight groups ~
---
---
--- General highlights ~
---
--- * `SuperKanbanNormal`                - Main plugin UI highlight
--- * `SuperKanbanBorder`                - Border of all windows
--- * `SuperKanbanWinbar`                - Winbar for all windows
--- * `SuperKanbanBubble`                  - Bubble/tab UI element
--- * `SuperKanbanBubbleEdge`              - Edge of Bubble/tab element
---
--- These are base highlight groups used throughout SuperKanban. Other specific
--- highlight groups (e.g. `SuperKanbanBoardNormal`, `SuperKanbanListNormal`,
--- `SuperKanbanCardNormal`) inherit from them.
---
--- Board window ~
---
--- * `SuperKanbanBoardNormal`           - Board window content
--- * `SuperKanbanBoardBorder`           - Border of board window
--- * `SuperKanbanBoardWinbar`           - Winbar of board window
--- * `SuperKanbanBoardFileName`         - Name of board file
--- * `SuperKanbanBoardFileNameEdge`     - Edge of file name field
--- * `SuperKanbanBoardScrollInfo`       - Scroll info display
--- * `SuperKanbanBoardScrollInfoEdge`   - Edge of scroll info
---
--- List window ~
---
--- * `SuperKanbanListNormal`            - List window content
--- * `SuperKanbanListBorder`            - Border of list window
--- * `SuperKanbanListWinbar`            - Winbar of list window
--- * `SuperKanbanListTitleBottom`       - Title label below list
---
--- Card window ~
---
--- * `SuperKanbanCardNormal`            - Card window content
--- * `SuperKanbanCardNormalNC`          - Card content (unfocused)
--- * `SuperKanbanCardBorder`            - Card window border
--- * `SuperKanbanCardBorderNC`          - Border (unfocused card)
--- * `SuperKanbanCardWinBar`            - Winbar of card window
--- * `SuperKanbanCardWinbarNC`          - Winbar (unfocused card)
---
--- Card content ~
---
--- * `SuperKanbanNone`                  - Empty or default content
--- * `SuperKanbanTag`                   - Tag inside a card
--- * `SuperKanbanDueDate`               - Due date field
--- * `SuperKanbanCheckMark`             - Checkbox (unchecked)
--- * `SuperKanbanCheckMarkDone`         - Checkbox (checked)
--- * `SuperKanbanLink`                  - Link text inside card
--- * `SuperKanbanLinkDelimiter`         - Link brackets/edges
---
--- Note window ~
---
--- * `SuperKanbanNoteNormal`            - Note window content
--- * `SuperKanbanNoteNormalNC`          - Note content (unfocused)
--- * `SuperKanbanNoteBorder`            - Border of note window
--- * `SuperKanbanNoteTitle`             - Note title text
--- * `SuperKanbanNoteTitleEdge`         - Edge of note title
---
--- Date Picker window ~
---
--- * `SuperKanbanDatePickerNormal`      - Date picker content
--- * `SuperKanbanDatePickerBorder`      - Date picker border
--- * `SuperKanbanDatePickerTitle`       - Date picker title
--- * `SuperKanbanDatePickerWeekDays`    - Weekday labels `(Su Mo Tu We Th Fr Sa)`
--- * `SuperKanbanDatePickerSeparator`   - Line between Weekday labels & dates
--- * `SuperKanbanDatePickerToday`       - Highlight for today
--- * `SuperKanbanDatePickerCursor`      - Highlighted cursor date
---@tag super-kanban-highlight-groups
---@toc_entry 7. Highlight groups

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

local default = false
function M.setup()
  local get_hl = require('super-kanban.utils.hl').get_hl

  -- stylua: ignore
  require('super-kanban.utils.hl').set_hl({
    Normal                = 'NormalFloat',
    Border                = 'FloatBorder',
    Bubble                = 'String',
    BubbleEdge            = 'SuperKanbanBubble',

    BoardNormal           = 'SuperKanbanNormal',
    BoardBorder           = 'SuperKanbanBorder',
    BoardWinbar           = 'SuperKanbanBoardNormal',
    BoardFileName         = 'Constant',
    BoardFileNameEdge     = 'Constant',
    BoardScrollInfo       = 'SuperKanbanBubble',
    BoardScrollInfoEdge   = 'SuperKanbanBubbleEdge',

    -- List window
    ListNormal            = 'SuperKanbanNormal',
    ListBorder            = 'SuperKanbanBorder',
    ListWinbar            = 'Search',
    ListTitleBottom       = 'String',

    -- Card window
    CardNormal            = 'CursorLine', -- Use darker color use to show active card
    CardNormalNC          = 'SuperKanbanListNormal',
    -- CardBorder
    CardBorderNC          = 'SuperKanbanListBorder',
    CardWinBar            = 'SuperKanbanCardNormal',
    CardWinbarNC          = 'SuperKanbanCardNormalNC',

    -- Card content
    None                  = { fg = 'NONE' },
    Tag                   = 'Constant' ,
    DueDate               = 'Keyword',
    CheckMark             = 'SuperKanbanNone',
    CheckMarkDone         = 'String',
    Link                  = 'Function' ,
    LinkDelimiter         = '@punctuation.bracket',

    -- Note window
    NoteNormal            = 'SuperKanbanNormal',
    NoteNormalNC          = 'SuperKanbanNoteNormal',
    NoteBorder            = 'SuperKanbanBorder',
    NoteTitle             = 'SuperKanbanBubble' ,
    NoteTitleEdge         = 'SuperKanbanBubbleEdge' ,

    -- Date Picker window
    DatePickerNormal      = 'SuperKanbanNormal' ,
    DatePickerBorder      = 'SuperKanbanBorder',
    DatePickerTitle       = 'Constant' ,
    DatePickerWeekDays    = 'String',
    DatePickerSeparator   = 'String',
    DatePickerToday       = 'SuperKanbanTag',
    DatePickerCursor      = 'Cursor',
  }, { prefix = prefix, default = default })

  local border_fg = get_hl('SuperKanbanCardBorderNC')
  local _, card_focus_bg = get_hl('SuperKanbanCardNormal', nil, '#222222')

  -- stylua: ignore
  require('super-kanban.utils.hl').set_hl({
    -- Card window
    CardBorder            = { fg = border_fg, bg = card_focus_bg }, -- Use darker color use to show active card
  }, { prefix = prefix, default = default })
end

return M
