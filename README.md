# notes.nvim

A simple note taking plugin for neovim. It is inspired by [denote](https://github.com/protesilaos/denote). This plugin is designed to be used with [mini.pick](https://github.com/echasnovski/mini.pick) and [marksman](https://github.com/artempyanykh/marksman).

## Features

- **Create Notes**: Easily create new notes with a title and tags.
- **Search Notes**: Search for notes within a specified directory.
- **Live Grep**: Perform live grep searches within your notes.

## Installation

Using [`vim.pack`](https://github.com/folke/zen-mode.nvim):

```lua
vim.pack.add({ "https://github.com/phrmendes/notes.nvim" })
```

As dependencies, you need to have [fd](https://github.com/sharkdp/fd) and [ripgrep](https://github.com/BurntSushi/ripgrep) installed.

## Setup

```lua
require("notes").setup({
  path = vim.env.HOME .. "/Documents/notes",
  picker = "snacks" -- or "mini"
})
```

## Usage

Suggested keybindings:

```lua
vim.keymap.set("n", "<leader>ns", function() require("notes").search() end, { desc = "Search notes" })
vim.keymap.set("n", "<leader>n/", function() require("notes").grep_live() end, { desc = "Live grep notes" })
vim.keymap.set("n", "<leader>nn", function() require("notes").new() end, { desc = "New note" })
```

Check the [help file](./doc/notes.txt) for more information.
