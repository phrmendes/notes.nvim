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

---@type table<string, fun(opts: boolean | table | nil)>
local servers = {
	marksman = function(opts)
		if not opts or (opts ~= true and opts.enabled == false) then return end
		vim.lsp.enable("marksman")
	end,
	ltex_plus = function(opts)
		if not opts or (opts ~= true and opts.enabled == false) then return end
		local lsp = require("notes.lsp")
		lsp.setup_code_actions()

		if type(opts) ~= "table" then
			vim.lsp.enable("ltex_plus")
			return
		end

		local settings = vim.tbl_extend("force", {}, opts)
		settings.enabled = nil

		local lang = type(settings.languages) == "table" and settings.languages or {}
		settings.language = lang.default or settings.language or "en-US"
		settings.languages = lang.additionals or {}

		local persisted = lsp.read_persisted_data()
		settings.dictionary = persisted.dictionary
		settings.disabledRules = persisted.disabledRules
		settings.hiddenFalsePositives = persisted.hiddenFalsePositives

		vim.lsp.config("ltex_plus", { settings = { ltex = settings } })
		vim.lsp.enable("ltex_plus")
	end,
}

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

	if not merged.lsp then return end
	vim.iter(servers):each(function(name, setup) setup(merged.lsp[name]) end)
end

--- Swap the active picker at runtime
---@param name string Backend name ("native", "mini", "custom", or registered)
function config.set_picker(name) config.picker = require("notes.picker")[name] end

return config
