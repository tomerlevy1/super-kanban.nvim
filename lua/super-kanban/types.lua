---@class kanban.TaskData
---@field title string
---@field check string
---@field due table
---@field tag table

---@class kanban.TaskListData
---@field title string
---@field tasks kanban.TaskData[]

---@class kanban.Markdown
---@field lists kanban.TaskListData[]

---@class kanban.TaskList.Ctx :kanban.TaskListUI[]
---@field tasks kanban.TaskUI[]

---@class kanban.Ctx
---@field root kanban.RootUI
---@field lists kanban.TaskList.Ctx[]
