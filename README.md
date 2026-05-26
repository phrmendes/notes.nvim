# notes.nvim

A simple note-taking plugin for Neovim, inspired by [denote](https://github.com/protesilaos/denote). Uses pure Neovim APIs with optional `mini.pick` integration.

## Features

- **Create Notes**: Easily create new notes with a title and tags. Empty titles become `"untitled"`.
- **Journal**: Open or create daily journal entries with automatic `#journal` tagging
- **Search Notes**: Find notes in your notes directory
- **Live Grep**: Search note contents with ripgrep
- **Custom Backends**: Register custom picker backends via `register_picker()`

## Requirements

- Neovim 0.10+ (for `vim.uv`, `vim.fs`, `vim.system`)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for native grep)
- [fd](https://github.com/sharkdp/fd) (optional, for mini.pick backend)
- [mini.pick](https://github.com/echasnovski/mini.nvim) (optional, auto-detected)

## Installation

Add the plugin URL to your `vim.pack.add()` call:

```lua
vim.pack.add({ "https://github.com/phrmendes/notes.nvim" })
```

## Setup

```lua
require("notes").setup({
  path = vim.fs.joinpath(vim.env.HOME, "Documents", "notes"),
  -- picker = "native",  -- or "mini", auto-detected if omitted
})

-- Suggested keybindings
vim.keymap.set("n", "<leader>nn", function() require("notes").new() end, { desc = "New note" })
vim.keymap.set("n", "<leader>ns", function() require("notes").search() end, { desc = "Search notes" })
vim.keymap.set("n", "<leader>n/", function() require("notes").grep() end, { desc = "Grep notes" })
vim.keymap.set("n", "<leader>nj", function() require("notes").journal() end, { desc = "Journal" })
```

### Configuration

See `:help notes.NotesConfig` for all configuration options.

### Picker Auto-detection

When `picker` is not specified, auto-detection happens once at plugin load:

- If `mini.pick` is available → uses `mini.pick`
- Otherwise → uses native `vim.ui.select`

## Usage

### Commands

- `:Notes new` — Create a new note
- `:Notes search` — Search notes by filename
- `:Notes grep` — Grep note contents
- `:Notes journal [date] [tags]` — Open or create a journal entry

## Testing

This plugin uses [mini.test](https://github.com/echasnovski/mini.nvim) for testing.

### Run all tests

```bash
just test
```

### Run specific test file

```bash
just test_file tests/test_utils.lua
just test_file tests/test_note.lua
just test_file tests/test_picker.lua
just test_file tests/test_integration.lua
just test_file tests/test_journal.lua
```

### Test requirements

- `just` (command runner)
- Neovim 0.10+
- mini.nvim (auto-downloaded by test runner)

## License

Apache-2.0 License Copyright (c) 2024 Pedro Mendes
