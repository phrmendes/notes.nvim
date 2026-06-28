# notes.nvim

A simple note-taking plugin for Neovim, inspired by [denote](https://github.com/protesilaos/denote). Notes are plain `.md` files with a date prefix and random ID. Optional `mini.pick` integration.

For full documentation, see [`:help notes.nvim`](doc/notes.txt).

## Quick start

```lua
require("notes").setup({
  path = vim.fs.joinpath(vim.env.HOME, "Documents", "notes"),
})

-- Suggested keybindings
vim.keymap.set("n", "<leader>nn", function() require("notes").new() end, { desc = "New note" })
vim.keymap.set("n", "<leader>ns", function() require("notes").search() end, { desc = "Search notes" })
vim.keymap.set("n", "<leader>n/", function() require("notes").grep() end, { desc = "Grep notes" })
vim.keymap.set("n", "<leader>nj", function() require("notes").journal() end, { desc = "Journal" })
```

## Installation

With [vim.pack](https://neovim.io/doc/user/usr_05.html#vim.pack):

```lua
vim.pack.add({ "https://github.com/phrmendes/notes.nvim" })
```

With a plugin manager of your choice, install `phrmendes/notes.nvim`.

## Commands

| Command | Description |
|---------|-------------|
| `:Notes new` | Create a new note |
| `:Notes search` | Search notes by filename |
| `:Notes grep` | Grep note contents |
| `:Notes journal [date] [tags]` | Open or create a journal entry |

## Requirements

- Neovim 0.10+ (for `vim.uv`, `vim.fs`, `vim.system`)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for grep)
- [mini.pick](https://github.com/echasnovski/mini.nvim) (optional, for the `mini` picker backend)

## Development

This project uses [devenv](https://devenv.sh). Inside a devenv shell:

```bash
test     # run the test suite
doc      # regenerate doc/notes.txt
```

## License

Apache-2.0 — Copyright (c) 2024 Pedro Mendes
