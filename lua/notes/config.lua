--- A simple note taking plugin for neovim.
---

---@class UserConfig
---@field path string Path to the notes directory
---@field picker "native" | "mini" Picker backend
---@field journal NotesJournalConfig | nil Journal configuration

---@class PickerBackend
---@field files fun(dir: string)
---@field grep fun(dir: string)

local M = {}
local utils = require("notes.utils")

local default_picker = pcall(require, "mini.pick") and "mini" or "native"

---@type UserConfig
local defaults = {
	path = vim.env.HOME .. "/Documents/notes",
	picker = default_picker,
	journal = {
		path = nil,
		title_format = "%Y-%m-%d",
		filename_format = "%Y-%m-%d",
	},
}

---@type string
M.path = nil

---@type PickerBackend
M.picker = nil

---@class NotesJournalConfig
---@field path string
---@field title_format string
---@field filename_format string

---@type NotesJournalConfig
M.journal = {}

--- Setup configuration
---@param opts UserConfig | nil User configuration options
function M.setup(opts)
	opts = opts or {}

	local merged = vim.tbl_deep_extend("force", defaults, opts)

	M.path = merged.path
	M.picker = require("notes.picker")[merged.picker]

	if utils.mkdirp(M.path) then
		vim.notify("Created notes directory at: " .. M.path, vim.log.levels.INFO)
	end

	M.journal.path = merged.journal.path or vim.fs.joinpath(M.path, "journal")
	M.journal.title_format = merged.journal.title_format
	M.journal.filename_format = merged.journal.filename_format

	utils.mkdirp(M.journal.path)
end

return M
