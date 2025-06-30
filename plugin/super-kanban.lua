if vim.g.loaded_superkanban == 1 then
  return
end
vim.g.loaded_superkanban = 1

-- Setup highlights
require('super-kanban.highlights').setup()
vim.api.nvim_create_autocmd('ColorScheme', {
  group = vim.api.nvim_create_augroup('superkanban_hl', { clear = true }),
  callback = function()
    require('super-kanban.highlights').setup()
  end,
})

-- Setup user_command
vim.api.nvim_create_user_command('SuperKanban', function(...)
  require('super-kanban.command')._command(...)
end, {
  nargs = '*',
  complete = "custom,v:lua.require'super-kanban.command'.get_completion",
  desc = 'SuperKanban',
})
