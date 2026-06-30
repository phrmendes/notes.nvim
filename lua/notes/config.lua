--- A simple note taking plugin for neovim.

local config = {}
local utils = require("notes.utils")

local default_picker = pcall(require, "mini.pick") and "mini" or "native"

---@type UserConfig
local defaults = {
	path = vim.env.HOME .. "/Documents/notes",
	picker = default_picker,
	lsp = { marksman = true, ltex_plus = true },
	journal = { title_format = "%Y-%m-%d" },
}

---@type string
config.path = nil

---@type PickerBackend?
config.picker = nil

---@type NotesJournalConfig
config.journal = {}

--- Setup configuration
---@param opts UserConfig | nil User configuration options
function config.setup(opts)
	opts = opts or {}

	local merged = vim.tbl_deep_extend("force", defaults, opts)

	config.path = merged.path

	config.set_picker(merged.picker)

	if utils.mkdirp(config.path) then vim.notify("Created notes directory at: " .. config.path, vim.log.levels.INFO) end

	config.journal.path = merged.journal.path or vim.fs.joinpath(config.path, "journal")
	config.journal.title_format = merged.journal.title_format

	utils.mkdirp(config.journal.path)

	if merged.lsp then
		if merged.lsp.marksman then vim.lsp.enable("marksman") end
		if merged.lsp.ltex_plus then
			require("notes.lsp").setup_code_actions()
			vim.lsp.enable("ltex_plus")
		end
	end
end

--- Swap the active picker at runtime
---@param name string Backend name ("native", "mini", "custom", or registered)
function config.set_picker(name) config.picker = require("notes.picker")[name] end

return config
