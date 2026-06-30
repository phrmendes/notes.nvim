--- A simple note taking plugin for neovim.

local config = {}
local utils = require("notes.utils")

local default_picker = pcall(require, "mini.pick") and "mini" or "native"

---@type UserConfig
local defaults = {
	path = vim.env.HOME .. "/Documents/notes",
	picker = default_picker,
	lsp = { marksman = { enabled = true }, ltex_plus = { enabled = true } },
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
		local marksman = merged.lsp.marksman
		if marksman and (marksman == true or marksman.enabled ~= false) then vim.lsp.enable("marksman") end
		local ltex_plus = merged.lsp.ltex_plus
		if ltex_plus and (ltex_plus == true or ltex_plus.enabled ~= false) then
			require("notes.lsp").setup_code_actions()
			if type(ltex_plus) == "table" then
				local settings = vim.tbl_extend("force", {}, ltex_plus)
				settings.enabled = nil
				vim.lsp.config("ltex_plus", { settings = { ltex = settings } })
			end
			vim.lsp.enable("ltex_plus")
		end
	end
end

--- Swap the active picker at runtime
---@param name string Backend name ("native", "mini", "custom", or registered)
function config.set_picker(name) config.picker = require("notes.picker")[name] end

return config
