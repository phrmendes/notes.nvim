--- Picker module for notes.nvim

local picker = {}

local edit = require("notes.utils").edit
local list_md_files = require("notes.picker.utils").list_md_files
local get_picker = require("notes.picker.utils").get_picker

picker.native = require("notes.picker.native")
picker.mini = require("notes.picker.mini")

--- Handle a chosen item — parses file:lnum: or bare path, then opens it.
--- Override this to change how notes are opened.
---@type fun(choice: string|nil)
picker.on_choice = require("notes.picker.utils").on_choice

--- Search for notes (list .md files)
---@param dir string | nil Directory to search (defaults to config path)
function picker.files(dir)
	local config = require("notes.config")
	dir = dir or config.path

	local items = list_md_files(dir)
	get_picker().files(items, dir, edit)
end

--- Grep in notes
---@param dir string | nil Directory to search (defaults to config path)
function picker.grep(dir)
	local c = require("notes.config")
	dir = dir or c.path
	local glob = "*.md"

	get_picker().grep(dir, glob, picker.on_choice)
end

return picker
