local M = {}

--- Ensures the hl groups are always set, even after a colorscheme change.
---@param groups table<string, string|vim.api.keyset.highlight>
---@param opts? { prefix?:string, default?:boolean, managed?:boolean }
function M.set_hl(groups, opts)
  opts = opts or {}
  for hl_group, hl in pairs(groups) do
    hl_group = opts.prefix and opts.prefix .. hl_group or hl_group
    hl = type(hl) == 'string' and { link = hl } or hl --[[@as vim.api.keyset.highlight]]
    hl.default = opts.default
    -- if opts.managed ~= false then
    --   hl_groups[hl_group] = hl
    -- end
    vim.api.nvim_set_hl(0, hl_group, hl)
  end
end

---@param hl_name string
---@return string?
---@return string?
function M.get_hl(hl_name)
  local hl = vim.api.nvim_get_hl(0, { name = hl_name, link = false })
  local fg = hl.fg and string.format('#%06x', hl.fg)
  local bg = hl.bg and string.format('#%06x', hl.bg)
  return fg, bg
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
