---
--- A simple note taking plugin for neovim.
---
--- Apache-2.0 License Copyright (c) 2024 Pedro Mendes
---

local config = require("notes.config")
local journal = require("notes.journal")
local note = require("notes.note")
local picker = require("notes.picker")

local M = {}

--- Setup function
---@param opts UserConfig | nil Configuration options
function M.setup(opts) config.setup(opts) end

--- Create a new note
---@param path string | nil Path to create the note in
function M.new(path)
	vim.ui.input({ prompt = "Title: " }, function(title)
		if not title or title == "" then
			vim.notify("Note not created: title can't be empty.", vim.log.levels.ERROR)
			return
		end

		vim.ui.input({ prompt = "Tags (comma-separated): " }, function(tags) note.create(title, tags, path) end)
	end)
end

--- Open or create a journal entry
---@param date string | nil Date in YYYY-MM-DD format (defaults to today)
---@param tags string | nil Comma-separated tags (appended to #journal)
function M.journal(date, tags) journal.open(date, tags) end

--- Search for notes (in markdown files)
---@param path string | nil Path to search in
function M.search(path) picker.files(path) end

--- Live grep in notes (in markdown files)
---@param path string | nil Path to grep in
function M.grep(path) picker.grep(path) end

--- Register a custom picker backend
---
--- Use this to add support for pickers beyond the built-in "native" and "mini".
--- The backend must provide `files(dir)` and `grep(dir)` functions.
---
---@param name string Backend name (used as picker value in setup)
---@param backend table Backend with .files(dir) and .grep(dir) methods
---
--- Usage:
--- >lua
---   require("notes").register_picker("fzf", {
---     files = function(dir) ... end,
---     grep = function(dir) ... end,
---   })
---   require("notes").setup({ picker = "fzf" })
--- <
function M.register_picker(name, backend) picker.register(name, backend) end

local commands = {
	new = function() M.new() end,
	search = function() M.search() end,
	grep = function() M.grep() end,
	journal = function(args) M.journal(args[2], args[3]) end,
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

return M
