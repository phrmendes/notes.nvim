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

---@param marksman boolean | NotesMarksmanConfig | nil
local function enable_marksman(marksman)
	if not marksman or (marksman ~= true and marksman.enabled == false) then return end
	vim.lsp.enable("marksman")
end

---@param ltex_plus boolean | NotesLtexPlusConfig | nil
local function enable_ltex(ltex_plus)
	if not ltex_plus or (ltex_plus ~= true and ltex_plus.enabled == false) then return end
	local notes_lsp = require("notes.lsp")
	notes_lsp.setup_code_actions()
	if type(ltex_plus) ~= "table" then
		vim.lsp.enable("ltex_plus")
		return
	end
	local settings = vim.tbl_extend("force", {}, ltex_plus)
	settings.enabled = nil
	local lang = type(settings.languages) == "table" and settings.languages or {}
	settings.language = lang.default or settings.language or "en-US"
	settings.languages = lang.additionals or {}
	local persisted = notes_lsp.read_persisted_data()
	settings.dictionary = persisted.dictionary
	settings.disabledRules = persisted.disabledRules
	settings.hiddenFalsePositives = persisted.hiddenFalsePositives
	vim.lsp.config("ltex_plus", { settings = { ltex = settings } })
	vim.lsp.enable("ltex_plus")
end

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
	enable_marksman(merged.lsp.marksman)
	enable_ltex(merged.lsp.ltex_plus)
end

--- Swap the active picker at runtime
---@param name string Backend name ("native", "mini", "custom", or registered)
function config.set_picker(name) config.picker = require("notes.picker")[name] end

return config
