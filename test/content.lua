-- Example usage
local md_task = 'Some text @{2025/01/18} @{2025/01/20} and #tag1 #tag2'
local title, tags, due, date_obj = require('super-kanban.utils.text').extract_task_data_from_str(md_task)

print('Title:', title)
print('Tags:', table.concat(tags, ','))
print('Dates:', table.concat(due, ','))
print(date_obj.year, date_obj.month, date_obj.day)
