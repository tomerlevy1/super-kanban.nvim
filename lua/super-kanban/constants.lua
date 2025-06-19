local M = {
  checkbox_checked = 'x',
  checkbox_unchecked = ' ',
  org = {
    headings = {
      h1 = '*',
      h2 = '**',
      h3 = '***',
      h4 = '****',
      h5 = '*****',
      h6 = '******',
    },
  },
  markdown = {
    headings = {
      h1 = '#',
      h2 = '##',
      h3 = '###',
      h4 = '####',
      h5 = '#####',
      h6 = '######',
    },
  },
  board = {
    filetype = 'superkanban_board'
  },
  list = {
    filetype = 'superkanban_list'
  },
  card = {
    filetype = 'superkanban_card'
  },
}

return M
