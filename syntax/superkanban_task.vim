" Highlight full dates like @2025/01/18
syntax match KanbanDueDate /@\v\d{4}\/\d{1,2}\/\d{1,2}/
" Highlight short dates like @01/18
syntax match KanbanDueDateShort /@\d\{2}\/\d\{2}/

" Highlight tags like #study
syntax match KanbanTaksTag /#\w\+/
