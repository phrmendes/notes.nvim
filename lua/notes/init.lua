--- *notes.nvim* Note-taking in Neovim
---
--- Apache-2.0 License Copyright (c) 2024 Pedro Mendes
---
--- Features:
---
--- - Create notes with title and tags. Notes are plain `.md` files named with
---   a date prefix and random 4-letter ID.
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
--- After setup, use the public functions or the `:Notes` user command:
---
--- >lua
---   require('notes').new()           -- create a note
---   require('notes').journal()       -- open today's journal entry
---   require('notes').search()        -- search by filename
---   require('notes').grep()          -- grep note contents
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
--- # Configuration ~
---
--- See |notes.NotesConfig| for the configuration class. Default values:
---
--- - `path` — `~/Documents/notes`
--- - `picker` — `"native"` (or `"mini"` if `mini.pick` is available)
--- - `journal.title_format` — `"%Y-%m-%d"`
---
--- # Picker backends ~
---
--- The active picker is a `PickerBackend` table with `files(items, dir, on_choice)`
--- and `grep(dir, glob, on_choice)` methods. Notes.nvim handles file opening;
--- backends only deal with display and selection.
---
--- Built-in: `native` (vim.ui), `mini` (mini.pick). To add a new backend,
--- create a module under `lua/notes/picker/` and require it from
--- `lua/notes/picker/init.lua`.

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
---   - {path} `(string)` Notes directory
---   - {picker} `(string)` Backend name: "native" or "mini"
---   - {journal} `(NotesJournalConfig|nil)` Journal settings
---
---@usage >lua
---   require('notes').setup({
---     path = vim.fs.joinpath(vim.env.HOME, 'Documents', 'notes'),
---     picker = 'mini',
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
