# notes.nvim

A simple note taking plugin for neovim. It is inspired by [denote](https://github.com/protesilaos/denote). This plugin is designed to be used with [mini.pick](https://github.com/echasnovski/mini.pick) and [marksman](https://github.com/artempyanykh/marksman).

## Features

- **Create Notes**: Easily create new notes with a title and tags.
- **Search Notes**: Search for notes within a specified directory.
- **Live Grep**: Perform live grep searches within your notes.

## Setup

```lua
return {
	"phrmendes/notes.nvim",
	dependencies = { "echasnovski/mini.nvim" },
	opts = {
		path = vim.env.HOME .. "/Documents/notes",
	},
	keys = {
		{ "<leader>ns", function() require("notes").search() end, desc = "Search" },
		{ "<leader>n/", function() require("notes").grep_live() end, desc = "Live grep" },
		{ "<leader>nn", function() require("notes").new() end, desc = "New" },
	},
}
```

## Usage

Check the [help file](./doc/notes.txt) for more information.
