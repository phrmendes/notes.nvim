# notes.nvim

A simple note-taking plugin for Neovim, inspired by [denote](https://github.com/protesilaos/denote). Uses pure Neovim APIs (`vim.ui`, `vim.uv`, `vim.fs`) with optional `mini.pick` integration.

## Features

- **Create Notes**: Easily create new notes with a title and tags. Empty titles become `"untitled"`.
- **Journal**: Open or create daily journal entries with automatic `#journal` tagging
- **Search Notes**: Fuzzy-find notes in your notes directory
- **Live Grep**: Search note contents with ripgrep
- **Custom Backends**: Register custom picker backends via `register_picker()`

## Requirements

- Neovim 0.10+ (for `vim.uv`, `vim.fs`, `vim.system`)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for native grep)
- [fd](https://github.com/sharkdp/fd) (optional, for mini.pick backend)
- [mini.pick](https://github.com/echasnovski/mini.nvim) (optional, auto-detected)

## Installation

Clone into Neovim's built-in package directory:

```bash
git clone --depth=1 https://github.com/phrmendes/notes.nvim \
  ${XDG_DATA_HOME:-~/.local/share}/nvim/site/pack/plugins/start/notes.nvim
```

## Setup

```lua
require("notes").setup({
  path = vim.env.HOME .. "/Documents/notes",
  -- picker = "native",  -- or "mini", auto-detected if omitted
})

-- Suggested keybindings
vim.keymap.set("n", "<leader>nn", function() require("notes").new() end, { desc = "New note" })
vim.keymap.set("n", "<leader>ns", function() require("notes").search() end, { desc = "Search notes" })
vim.keymap.set("n", "<leader>n/", function() require("notes").grep() end, { desc = "Grep notes" })
vim.keymap.set("n", "<leader>nj", function() require("notes").journal() end, { desc = "Journal" })
```

### Configuration

| Option                 | Default             | Description                                                 |
| ---------------------- | ------------------- | ----------------------------------------------------------- |
| `path`                 | `~/Documents/notes` | Directory to store notes                                    |
| `picker`               | auto-detected       | Picker backend: `"native"` (vim.ui) or `"mini"` (mini.pick) |
| `journal.path`         | `{path}/journal`    | Directory to store journal entries                          |
| `journal.title_format` | `"%Y-%m-%d"`        | `os.date` format for journal entry heading                  |

### Picker Auto-detection

When `picker` is not specified, auto-detection happens once at plugin load:

- If `mini.pick` is available → uses `mini.pick`
- Otherwise → uses native `vim.ui.select`

## Usage

### Commands

- `:lua require("notes").new()` - Create a new note (prompts for title and tags)
- `:lua require("notes").search()` - Search notes by filename
- `:lua require("notes").grep()` - Grep note contents
- `:lua require("notes").journal()` - Open today's journal entry (creates if absent)
- `:lua require("notes").journal("2026-05-25")` - Open a specific date's entry
- `:lua require("notes").journal(nil, "work, daily")` - Today's entry with custom tags (#journal always present)
- `:lua require("notes").register_picker("fzf", { files = ..., grep = ... })` - Register a custom picker backend

### Note Naming Convention

Notes are named: `YYYYMMDDXXXX-title.md`

- `YYYYMMDD` - Date of creation
- `XXXX` - Random 4-character ID (prevents collisions)
- `title` - Normalized title (lowercase, spaces → hyphens, special chars removed)
- Empty title → heading is `"untitled"`, filename is `YYYYMMDDXXXX-untitled.md`

Example: `20250124ABCD-my-meeting-notes.md`

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
```

### Test requirements

- `just` (command runner)
- Neovim 0.10+
- mini.nvim (auto-downloaded by test runner)

## License

MIT License Copyright (c) 2024 Pedro Mendes
