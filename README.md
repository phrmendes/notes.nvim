# notes.nvim

A simple note-taking plugin for Neovim, inspired by [denote](https://github.com/protesilaos/denote). Notes are plain `.md` files with a date prefix and random ID. Includes marksman and ltex-ls-plus LSP integration.

For full documentation, see [`:help notes.nvim`](doc/notes.txt).

## Installation

With [vim.pack](https://neovim.io/doc/user/usr_05.html#vim.pack) (Neovim 0.12+):

```lua
vim.pack.add({ "https://github.com/phrmendes/notes.nvim" })
```

## Quick start

```lua
-- init.lua
require("notes").setup({
  path = vim.fs.joinpath(vim.env.HOME, "Documents", "notes"),
})

-- Suggested keybindings
vim.keymap.set("n", "<leader>nn", function() require("notes").new() end, { desc = "Notes: new" })
vim.keymap.set("n", "<leader>ns", function() require("notes").search() end, { desc = "Notes: search" })
vim.keymap.set("n", "<leader>n/", function() require("notes").grep() end, { desc = "Notes: grep" })
vim.keymap.set("n", "<leader>nj", function() require("notes").journal() end, { desc = "Notes: journal" })
```

## Usage

| Command                        | Description                    |
| ------------------------------ | ------------------------------ |
| `:Notes new`                   | Create a new note              |
| `:Notes search`                | Search notes by filename       |
| `:Notes grep`                  | Grep note contents             |
| `:Notes journal [date] [tags]` | Open or create a journal entry |
| `:checkhealth notes`           | Verify installation            |

Or from Lua:

```lua
require("notes").new()               -- create a note
require("notes").journal()           -- open today's journal entry
require("notes").search()            -- search by filename
require("notes").grep()              -- grep note contents
require("notes").set_picker("mini")  -- switch picker at runtime
```

## Requirements

- Neovim 0.11+ (for `lsp/<server>.lua` runtime discovery)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for grep)
- [fd](https://github.com/sharkdp/fd) (for the `mini` picker backend)

### Optional

- [mini.pick](https://github.com/echasnovski/mini.nvim) — for the `mini` picker backend
- [marksman](https://github.com/artempyanykh/marksman) — for markdown LSP features
- [ltex-ls-plus](https://github.com/ltex-plus/ltex-ls-plus) — for grammar/spelling checks

## Related

- [denote](https://github.com/protesilaos/denote) — the Emacs package that inspired this plugin
- [ltex_extra.nvim](https://github.com/barreiroleo/ltex_extra.nvim) — richer ltex-ls-plus features (UI, statusline, scope management) on top of the basic integration shipped here

## Development

This project uses [devenv](https://devenv.sh). Inside a devenv shell:

```bash
test     # run the test suite
doc      # regenerate doc/notes.txt
```

## License

Apache-2.0 — Copyright (c) 2024 Pedro Mendes
