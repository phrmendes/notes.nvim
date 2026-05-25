---
--- Configuration module for notes.nvim
---

---@class UserConfig
---@field path string Path to the notes directory
---@field picker "native" | "mini" Picker backend

---@class PickerBackend
---@field files fun(dir: string)
---@field grep fun(dir: string)

local M = {}

local default_picker = pcall(require, "mini.pick") and "mini" or "native"

---@type UserConfig
local defaults = {
	path = vim.env.HOME .. "/Documents/notes",
	picker = default_picker,
}

---@type string
M.path = nil

---@type PickerBackend
M.picker = nil

--- Setup configuration
---@param opts UserConfig | nil User configuration options
function M.setup(opts)
	opts = opts or {}

	local merged = vim.tbl_deep_extend("force", defaults, opts)

	M.path = merged.path
	M.picker = require("notes.picker")[merged.picker]

	local stat = vim.uv.fs_stat(M.path)

	if not stat or stat.type ~= "directory" then
		vim.fs.mkdir(M.path, { parents = true })
		vim.notify("Created notes directory at: " .. M.path, vim.log.levels.INFO)
	end
end

return M
