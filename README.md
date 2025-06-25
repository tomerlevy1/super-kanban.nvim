# 🗂️ super-kanban.nvim

**A keyboard-centric, minimal, and customizable Kanban board plugin for Neovim.**

It supports Obsidian-style Markdown and Orgmode formats, with Treesitter-powered parsing and a focus on speed and clarity - right inside your editor.

---

## ✨ Features

- Keyboard-centric Kanban workflow built for Neovim
- Treesitter-based parsing for `Markdown` and `Orgmode` (`neorg` coming soon)
- Compatible with Obsidian Kanban-style markdown
- Supports tags, checkmarks, due dates, and note links in cards
- Built-in date picker for assigning due dates and sorting or archiving cards
- Time tracking support to log and review time spent on each task (`coming soon`)

---

## ⚙️ Requirements

### Required

- [snacks.nvim](https://github.com/folke/snacks.nvim) - component layout engine
- Treesitter parser for `markdown` or `org`

### Optional (but recommended)

- [orgmode.nvim](https://github.com/nvim-orgmode/orgmode) - for Org file support
- [flash.nvim](https://github.com/folke/flash.nvim) - for enhanced jump navigation

---

## 📦 Installation

### Using `lazy.nvim`

```lua
{
  "hasansujon786/super-kanban.nvim",
  dependencies = {
    "folke/snacks.nvim",           -- [required]
    "nvim-orgmode/orgmode",        -- [optional] Org format support
  },
  opts = {}, -- optional: pass your config table here
}
```

### Using `mini.deps`

```lua
require("mini.deps").add({
  source = "hasansujon786/super-kanban.nvim",
  depends = {
    { source = "folke/snacks.nvim" },       -- [required]
    { source = "nvim-orgmode/orgmode" },    -- [optional]
  },
})
```

---

## 🔧 Configuration

Call `setup()` in your config file to customize behavior:

```lua
require("super-kanban").setup({
  markdown = {
    notes_dir = "./tasks/",
    list_heading = "h2",
    default_template = {
      "## Backlog\n",
      "## Todo\n",
      "## Work in progress\n",
      "## Completed\n",
    },
  },
  mappings = {
    ["<cr>"] = "open_note",
    ["gD"] = "delete_card",
    ["<C-t>"] = "toggle_complete",
  },
})
```

See [`:h super-kanban-config-defaults`](https://github.com/hasansujon786/super-kanban.nvim/blob/main/doc/super-kanban.txt#L160) in the help file for all available options.

---

## ⌨️Keymaps

Define custom mappings using the `mappings` option. Each mapping can be:

- a string (built-in action name)
- a Lua function
- `false` (to disable the default)

Example:

```lua
mappings = {
  ['s'] = {
    callback = function()
      pick_window()
    end,
    desc = "Flash",
  },

  ['/'] = {
    callback = function(card, list, ctx)
      require("super-kanban.actions").search_card(card, list, ctx)
    end,
    nowait = true,
  },

  ['<cr>'] = false,
}
```

You can use all standard mapping options (`desc`, `nowait`, etc.)  
See `:h vim.keymap.set()` and `vim.keymap.set.Opts` for details.

---

## 📜 Commands

| Command               | Description                                      |
| --------------------- | ------------------------------------------------ |
| `:SuperKanban`        | Open the main board window                       |
| `:SuperKanban create` | Create a new Kanban file                         |
| `:SuperKanban close`  | Close the main board window                      |
| `:SuperKanban list`   | List-related actions (create, move, delete, etc) |
| `:SuperKanban card`   | Card-related actions (move, jump, date, etc)     |

See `:h :SuperKanban` for subcommand details.

---

## 📦 API

You can call functions directly via Lua:

```lua
require("super-kanban").open("todo.md")
require("super-kanban").create("my-board.md")
require("super-kanban").setup({ ... })
```

---

## 🎨 Highlight Groups

Fully themeable via highlight groups like:

- `SuperKanbanNormal`
- `SuperKanbanListBorder`
- `SuperKanbanCardNormal`
- `SuperKanbanDatePickerCursor`
- and more...

See [`:h super-kanban-highlight-groups`](https://github.com/hasansujon786/super-kanban.nvim/blob/main/doc/super-kanban.txt#L901) for the full list.

---

## 🧪 Contributing

Feel free to open issues or PRs if you have ideas or find bugs.
This plugin is still in early development, so feedback is welcome!

## 🙏 Acknowledgement

- Huge thanks to [arakkkkk/kanban.nvim](https://github.com/arakkkkk/kanban.nvim)
  it was one of the first Neovim Kanban plugins I tried, and it inspired me to
  build my own take on the idea.
