---
--- A simple note taking plugin for neovim.
---
--- MIT License Copyright (c) 2024 Pedro Mendes
---

local config = require("notes.config")
local note = require("notes.note")
local picker = require("notes.picker")

local M = {}

--- Setup function
---@param opts table | nil Configuration options
function M.setup(opts)
	config.setup(opts)
end

--- Create a new note
---@param path string | nil Path to create the note in
function M.new(path)
	vim.ui.input({ prompt = "Title: " }, function(title)
		if not title or title == "" then
			vim.notify("Note not created: title can't be empty.", vim.log.levels.ERROR)
			return
		end

		vim.ui.input({ prompt = "Tags (comma-separated): " }, function(tags)
			note.create(title, tags, path)
		end)
	end)
end

--- Search for notes (in markdown files)
---@param path string | nil Path to search in
function M.search(path)
	picker.files(path)
end

--- Live grep in notes (in markdown files)
---@param path string | nil Path to grep in
function M.grep(path)
	picker.grep(path)
end

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
function M.register_picker(name, backend)
	picker.register(name, backend)
end

return M
