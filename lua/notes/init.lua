--- *notes.nvim* Note-taking in Neovim
---
--- Apache-2.0 License Copyright (c) 2024 Pedro Mendes
---
--- Features:
---
--- - Create notes with title and tags. Notes are plain `.md` files named with
---   a date prefix and random 4-letter ID. Empty titles become "untitled".
---
--- - Daily journal entries with automatic `#journal` tagging. Heading format
---   is configurable via `journal.title_format`.
---
--- - Search notes by filename or live-grep note contents with `ripgrep`.
---
--- - Pluggable picker: `vim.ui.select` (default) or `mini.pick` when
---   available. Custom backends can be added by writing a module under
---   `lua/notes/picker/`.
---
--- - Optional marksman LSP integration via `lsp/marksman.lua`. Auto-loaded
---   by Neovim 0.11+ runtime discovery; `setup()` auto-enables it.
---
--- - Optional ltex-ls-plus integration via `lsp/ltex_plus.lua`. Grammar and
---   spelling checker for markdown, tex, and typst. Dictionaries, disabled
---   rules, and hidden false positives are persisted as JSON in
---   `~/.local/share/nvim/ltex/`. All functionality is exposed through the
---   LSP — diagnostics, code actions, and `_ltex.*` commands — with no
---   plugin-side user commands or keymaps. For a richer feature set
---   (statusline, UI, scope management), see
---   [ltex_extra.nvim](https://github.com/barreiroleo/ltex_extra.nvim) which
---   builds on the same LSP server.
---
--- # Setup ~
---
--- Call `require('notes').setup({...})` once at startup. All other public
--- functions require setup to have been called first.
---
---@usage >lua
---   require('notes').setup({
---     path = vim.fs.joinpath(vim.env.HOME, 'Documents', 'notes'),
---   })
--- <
---
--- # Usage ~
---
--- Public functions:
---
--- >lua
---   require('notes').new()               -- create a note
---   require('notes').journal()           -- open today's journal entry
---   require('notes').search()            -- search by filename
---   require('notes').grep()              -- grep note contents
---   require('notes').set_picker('mini')  -- swap picker at runtime
--- <
---
--- Or from the command line:
---
--- >vim
---   :Notes new
---   :Notes search
---   :Notes grep
---   :Notes journal 2024-12-25 tag1,tag2
--- <
---
--- # Requirements ~
---
--- - Neovim 0.11+ (for `lsp/<server>.lua` runtime discovery and
---   `vim.lsp.enable`)
--- - [ripgrep](https://github.com/BurntSushi/ripgrep) (for grep)
---
--- # Optional ~
---
--- - [mini.pick](https://github.com/echasnovski/mini.nvim) — for the `mini`
---   picker backend
--- - [marksman](https://github.com/artempyanykh/marksman) — for markdown LSP
---   features
--- - [ltex-ls-plus](https://github.com/ltex-plus/ltex-ls-plus) — for grammar
---   and spelling checks
---
--- # Configuration ~
---
--- All options are passed to `setup({...})`. The full configuration class:
---
--- >lua
---   ---@class UserConfig
---   ---@field path string Notes directory
---   ---@field picker string Picker backend name: "native" or "mini"
---   ---@field lsp NotesLspConfig|nil LSP configuration
---   ---@field journal NotesJournalConfig|nil Journal configuration
--- <
---
--- Default values:
---
--- - `path` — `~/Documents/notes`
--- - `picker` — `"native"` (or `"mini"` if `mini.pick` is available)
--- - `lsp.marksman` — `true` (auto-enable marksman)
--- - `lsp.ltex_plus` — `true` (auto-enable ltex-ls-plus)
--- - `journal.title_format` — `"%Y-%m-%d"`
---
---@usage >lua
---   require('notes').setup({
---     path = vim.fs.joinpath(vim.env.HOME, 'Documents', 'notes'),
---     picker = 'mini',
---     lsp = {
---       marksman = true,    -- disable with `false`
---       ltex_plus = false,  -- only enable what you have installed
---     },
---     journal = { title_format = '%d/%m/%Y' },
---   })
--- <
---
--- # Picker backends ~
---
--- The active picker is a `PickerBackend` table with two methods:
--- `files(items, dir, on_choice)` and `grep(dir, glob, on_choice)`. The
--- plugin handles file opening; backends only deal with display and
--- selection.
---
--- - `"native"` — uses `vim.ui.select` (the default)
--- - `"mini"` — uses `mini.pick` (live grep, icons, etc.)
--- - Custom — write a module at `lua/notes/picker/<name>.lua` with
---   `files` and `grep` methods, then use `set_picker("<name>")`
---
--- Switch at runtime with `notes.set_picker("name")`.
---
--- # LSP integration ~
---
--- The plugin ships `lsp/marksman.lua` and `lsp/ltex_plus.lua` at the
--- project root. Neovim 0.11+ auto-discovers them when you call
--- `vim.lsp.enable("marksman")` or `vim.lsp.enable("ltex_plus")`. The
--- plugin's `setup()` triggers these enables automatically.
---
--- ## marksman ~
---
--- Markdown LSP — completion, hover, cross-file references, symbols.
--- Config lives in `lsp/marksman.lua` (8 lines, no client-side handlers).
--- Use `vim.lsp.buf.format()` to format a buffer manually.
---
--- ## ltex-ls-plus ~
---
--- Grammar and spelling checker for `.md`, `.tex`, and `.typst`. Three
--- layers of integration:
---
--- 1. **Diagnostics** — free via LSP. Squiggles appear automatically.
---
--- 2. **Code actions** — server provides 4 quick fixes (accept suggestion,
---    add to dictionary, disable rule, hide false positive). The plugin
---    adds one more: "Pick language" (opens `vim.ui.select` with
---    `settings.languages`, current language marked `[*]`).
---
--- 3. **LSP commands** — registered in `on_attach`:
---
---    - `_ltex.addToDictionary` (server) — appends words, persists to JSON
---    - `_ltex.disableRules` (server) — appends rule IDs, persists
---    - `_ltex.hideFalsePositives` (server) — appends, persists
---    - `_ltex.spellCheck` (client) — toggle grammar checking
---    - `_ltex.pickLanguage` (client) — `vim.ui.select` language picker
---    - `_ltex.checkDocument` (client) — request re-check
---
--- Persisted data lives at `~/.local/share/nvim/ltex/`:
---
--- >text
---   dictionary.json
---   disabledRules.json
---   hiddenFalsePositives.json
--- <
---
--- Each file is a JSON object: `{"en-US": ["word1", "word2"], ...}`.
--- Shared across all note projects — add a word in one notes dir, it's
--- available everywhere.
---
--- # Module structure ~
---
--- >text
---   lua/notes/
---   ├── init.lua          -- this file: public API + :Notes command
---   ├── config.lua        -- setup() + set_picker()
---   ├── types.lua         -- @class definitions (UserConfig, etc.)
---   ├── utils.lua         -- shared utilities
---   ├── note.lua          -- note.create()
---   ├── journal.lua       -- journal.open()
---   └── picker/           -- picker backends
---       ├── init.lua      -- orchestrator + get_picker()
---       ├── utils.lua     -- list_md_files, rg_search, on_choice
---       ├── native.lua    -- vim.ui backend
---       └── mini.lua      -- mini.pick backend
---
---   lsp/                  -- LSP config files (Neovim 0.11+ auto-discovered)
---   ├── marksman.lua
---   └── ltex_plus.lua
---
---   scripts/init.lua       -- bootstrap for tests
---   tests/                 -- mini.test suite (94 cases)
--- <
---
--- # Why no user commands ~
---
--- This plugin deliberately exposes no orchestrating code. Notes are
--- created/edited via the public Lua API or `:Notes` command. Picker
--- choice, LSP toggles, language switching — all done through LSP
--- commands, code actions, or the public Lua API.
---
--- Users who want keymaps add their own:
---
--- >lua
---   vim.keymap.set("n", "<leader>nn", function() require("notes").new() end, { desc = "Notes: new" })
---   vim.keymap.set("n", "<leader>ns", function() require("notes").search() end, { desc = "Notes: search" })
---   vim.keymap.set("n", "<leader>n/", function() require("notes").grep() end, { desc = "Notes: grep" })
---   vim.keymap.set("n", "<leader>nj", function() require("notes").journal() end, { desc = "Notes: journal" })
--- <
---
--- # Checkhealth ~
---
--- Run `:checkhealth notes` to verify installation:
---
--- - Configuration validity
--- - `marksman` and `ltex-ls-plus` binaries on PATH
--- - Persisted dictionary sizes
--- - LSP server attachment status

local config = require("notes.config")
local journal = require("notes.journal")
local note = require("notes.note")
local picker = require("notes.picker")

local notes = {}

--- Setup the plugin
---
--- Must be called once before any other public function. Creates the notes
--- directory, resolves the picker backend, and sets the journal directory.
---
--- Parameters ~
--- {opts} `(UserConfig|nil)` Configuration options
---
---@usage >lua
---   require('notes').setup({
---     path = vim.fs.joinpath(vim.env.HOME, 'Documents', 'notes'),
---     picker = 'mini',
---     lsp = { marksman = true, ltex_plus = true },
---     journal = { title_format = '%d/%m/%Y' },
---   })
--- <
function notes.setup(opts) config.setup(opts) end

--- Create a new note
---
--- Prompts for title and tags interactively, then creates the note and opens
--- it. Empty title becomes "untitled".
---
--- Parameters ~
--- {path} `(string|nil)` Directory to create the note in (defaults to config path)
---
---@usage >lua
---   require('notes').new()  -- uses configured notes path
---   require('notes').new('/some/other/dir')
--- <
function notes.new(path)
	vim.ui.input({ prompt = "Title: " }, function(title)
		vim.ui.input({ prompt = "Tags (comma-separated): " }, function(tags) note.create(title, tags, path) end)
	end)
end

--- Open or create a journal entry
---
--- Journal entries are stored in `{path}/journal/` (configurable) and always
--- include the `#journal` tag. Opens existing entry for the date or creates
--- a new one.
---
--- Parameters ~
--- {date} `(string|nil)` Date in YYYY-MM-DD format (defaults to today)
--- {tags} `(string|nil)` Comma-separated tags appended to #journal
---
---@usage >lua
---   require('notes').journal()                  -- today
---   require('notes').journal('2024-12-25')      -- specific date
---   require('notes').journal(nil, 'work, ideas')  -- today with custom tags
--- <
function notes.journal(date, tags) journal.open(date, tags) end

--- Search notes by filename
---
--- Lists all `.md` files in the notes directory using the configured picker.
--- Selecting a file opens it.
---
--- Parameters ~
--- {path} `(string|nil)` Directory to search in (defaults to config path)
---
---@usage >lua
---   require('notes').search()
--- <
function notes.search(path) picker.files(path) end

--- Grep note contents
---
--- Prompts for a pattern (or live-updates with mini.pick) and shows matching
--- lines. Selecting a match opens the file at the line number.
---
--- Parameters ~
--- {path} `(string|nil)` Directory to search in (defaults to config path)
---
---@usage >lua
---   require('notes').grep()
--- <
function notes.grep(path) picker.grep(path) end

--- Trigger the ltex-ls-plus language picker
---
--- Calls `_ltex.pickLanguage` if ltex-ls-plus is attached to the current
--- buffer. Shows a `vim.ui.select` list of the configured languages (with the
--- active language marked). Warns if no languages are configured in setup.
---
---@usage >lua
---   require('notes').ltex_pick_language()
--- <
function notes.ltex_pick_language()
	local cmd = vim.lsp.commands["_ltex.pickLanguage"]
	if cmd then
		cmd({})
	else
		vim.notify("ltex-ls-plus not attached to this buffer", vim.log.levels.WARN)
	end
end

--- Swap the active picker at runtime
---
--- Changes the backend used by subsequent `search()` and `grep()` calls
--- without requiring re-calling `setup()`.
---
--- Parameters ~
--- {name} `(string)` Backend name: "native" or "mini"
---
---@usage >lua
---   require('notes').set_picker('mini')
---   require('notes').set_picker('native')
--- <
function notes.set_picker(name) config.set_picker(name) end

local commands = {
	new = function() notes.new() end,
	search = function() notes.search() end,
	grep = function() notes.grep() end,
	journal = function(args) notes.journal(args[2], args[3]) end,
}

vim.api.nvim_create_user_command("Notes", function(opts)
	local args = vim.split(opts.args, "%s+", { trimempty = true })
	local sub = args[1]
	local handler = commands[sub]

	if not handler then
		vim.notify("Unknown Notes command: " .. (sub or ""), vim.log.levels.ERROR)
		return
	end

	handler(args)
end, {
	nargs = "*",
	desc = "Notes commands: " .. table.concat(vim.tbl_keys(commands), ", "),
	complete = function() return vim.tbl_keys(commands) end,
})

return notes
