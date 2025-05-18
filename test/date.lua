-- Example Usage
local text = "Some text @2025/01/18 and @2025/1/8 or @2025/1/08 @2025/01/8 #tag1 #tag2"

local function parse_title_and_tags(raw)
	local tags = {}
	local due = {}

	-- extract tags
	local title = raw:gsub("#%S+", function(tag)
		table.insert(tags, tag) -- tag:sub(2) remove '#' prefix
		return ""
	end)

	-- extract dates
	title = title:gsub("(@%d%d%d%d/%d%d?/%d%d?)", function(date)
		table.insert(due, date)
		return ""
	end)

	-- clean up spaces
	title = title:gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")

	return title, tags, due
end

-- Example usage
local title, tags, due = parse_title_and_tags(text)

print("Title:", "." .. title .. ".")
print("Tags:", table.concat(tags, ","))
print("Dates:", table.concat(due, ","))
