# notes.nvim

A simple note taking plugin for neovim. It is inspired by [denote](https://github.com/protesilaos/denote). This plugin is designed to be used with [mini.pick](https://github.com/echasnovski/mini.pick) and [marksman](https://github.com/artempyanykh/marksman).

## Features

- **Create Notes**: Easily create new notes with a title and tags.
- **Search Notes**: Search for notes within a specified directory.
- **Live Grep**: Perform live grep searches within your notes.

## Installation

### Using mini.deps

Installation instructions: [mini.deps](https://github.com/echasnovski/mini.deps#installation)

```lua
local add = require("mini.deps").add

add({
    source = "phrmendes/notes.nvim",
    depends = { "echasnovski/mini.nvim" },
    -- depends = { "echasnovski/mini.pick" },
})
```

## Configuration

You can configure the plugin by calling the `setup` function. The default path for notes is `~/Documents/notes`.

```lua
local later = require("mini.deps")

later(function()
  require("notes").setup({ path = "path/to/your/notes" })
end)
```

## Usage

Check the [help file](./doc/notes.txt) for more information.

## Backlog

- [ ] Add tests.
