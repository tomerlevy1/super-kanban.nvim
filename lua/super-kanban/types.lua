---@class kanban.TaskMD
---@field title string
---@field check string
---@field due table
---@field tag table

---@class kanban.TaskListMD
---@field title string
---@field tasks kanban.TaskMD[]

---@class kanban.Markdown
---@field lists kanban.TaskListMD[]
