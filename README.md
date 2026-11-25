# notes.nvim

A simple note-taking plugin for Neovim, inspired by [denote](https://github.com/protesilaos/denote). Notes are plain `.md` files with a date prefix and random ID. Includes marksman and ltex-ls-plus LSP integration.

For full documentation, see [`:help notes.nvim`](doc/notes.txt).

## Installation

With [vim.pack](https://neovim.io/doc/user/usr_05.html#vim.pack) (Neovim 0.12+):

```lua
vim.pack.add({ "https://github.com/phrmendes/notes.nvim" })
```

## Pin a release

After the first release, pin a tag with vim.pack (Neovim 0.12+):

```lua
vim.pack.add({ { src = "https://github.com/phrmendes/notes.nvim", version = "v1.0.0" } })
```

For Nix, pin the same tag and add the plugin package:

```nix
inputs.notes.url = "github:phrmendes/notes.nvim/v1.0.0";
# Add inputs.notes.packages.${pkgs.system}.notes-nvim to your Neovim plugins.
```

Create the first tag and GitHub release manually. The release workflow waits for a tag.

## Development and releases

Enter the devenv environment and use Commitizen to create Conventional Commits.

```sh
devenv shell -- cz commit
devenv test
```

The git hooks check commit messages and format code. The docs hook generates the help file.
For the first release, generate the changelog and review it:

```sh
devenv shell -- cz changelog --unreleased-version v1.0.0
```

Commit the changelog, then create and publish the `v1.0.0` tag manually.
After the first release, Commitizen updates the version and changelog when checks pass on main.
The workflow creates a tag and a GitHub release. Non-bot commits must have verified signatures.
The repository must allow the workflow token to create release commits and tags on main.

## Quick start

```lua
-- init.lua
require("notes").setup({
  path = vim.fs.joinpath(vim.env.HOME, "Documents", "notes"),
  picker = "mini", -- or "native" (default)
  journal = { title_format = "%Y-%m-%d" },
  lsp = {
    marksman = { enabled = true },
    ltex_plus = {
      enabled = true,
      languages = { default = "en-US", additionals = { "pt-BR" } },
    },
  },
})

-- Suggested keybindings
vim.keymap.set("n", "<leader>nn", function() require("notes").new() end, { desc = "Notes: new" })
vim.keymap.set("n", "<leader>ns", function() require("notes").search() end, { desc = "Notes: search" })
vim.keymap.set("n", "<leader>n/", function() require("notes").grep() end, { desc = "Notes: grep" })
vim.keymap.set("n", "<leader>nj", function() require("notes").journal() end, { desc = "Notes: journal" })
```

## Preconfigured LSP servers

The plugin ships `lsp/marksman.lua` and `lsp/ltex_plus.lua` at the project root.
Neovim 0.11+ auto-discovers them. `setup()` enables marksman. For ltex-ls-plus it
registers the settings and the helper server only. Start LTeX with the
"Enable spellcheck" code action or `vim.lsp.enable("ltex_plus")`.
Disable individually with `lsp = { marksman = { enabled = false }, ltex_plus = { enabled = false } }`
(or `lsp = false` to disable all).

### marksman

Markdown LSP — completion, hover, cross-file references, rename, and workspace symbol search (tags, headings). All standard LSP features — no plugin wrappers needed. Bind `vim.lsp.buf.*` yourself:

```lua
vim.keymap.set("n", "<leader>nR", vim.lsp.buf.rename, { desc = "Notes: rename (marksman)" })
vim.keymap.set("n", "<leader>nb", vim.lsp.buf.references, { desc = "Notes: backlinks (marksman)" })
vim.keymap.set("n", "<leader>nS", vim.lsp.buf.workspace_symbol, { desc = "Notes: search symbols/tags (marksman)" })
```

### ltex-ls-plus

Grammar and spelling checker for `.md`, `.tex`, and `.typst`. Available as [code actions](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#textDocument_codeAction) (accept suggestion, add to dictionary, disable rule, hide false positive) and `_ltex.*` [LSP commands](https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#workspace_executeCommand). See `:help notes.nvim` for the full reference.

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

### Optional

- [fd](https://github.com/sharkdp/fd) (for the `mini` picker backend)
- [mini.pick](https://github.com/echasnovski/mini.nvim) — for the `mini` picker backend
- [marksman](https://github.com/artempyanykh/marksman) — for markdown LSP features
- [ltex-ls-plus](https://github.com/ltex-plus/ltex-ls-plus) — for grammar/spelling checks

## Related

- [denote](https://github.com/protesilaos/denote) — the Emacs package that inspired this plugin
- [ltex_extra.nvim](https://github.com/barreiroleo/ltex_extra.nvim) — richer ltex-ls-plus features (UI, statusline, scope management) on top of the basic integration shipped here

## License

Apache-2.0 — Copyright (c) 2024 Pedro Mendes
