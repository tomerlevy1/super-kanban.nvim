" Highlight tags like #study
syntax match KanbanTaksTag /#\w\+/

" Highlight dates
" @{2025-04-25}
" @{2025/04/25}
" @{2025,04,25}

" @{25/04/25}
" @{25-04-25}
" @{25,04,25}

" @{25/04}
" @{25-04}
" @{25,04}
syntax match KanbanDueDate /@\v\{\d{2,4}[-/,]\d{1,2}([-/,]\d{1,2})?\}/
