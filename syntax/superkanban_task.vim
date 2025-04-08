" Highlight full dates like @2025/01/18
syntax match KanbanDueDate /@\d\{4}\/\d\{2}\/\d\{2}/
" Highlight short dates like @01/18
syntax match KanbanDueDateShort /@\d\{2}\/\d\{2}/

" Highlight tags like #study
syntax match KanbanTaksTag /#\w\+/
