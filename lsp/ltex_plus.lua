---@class LtexSettings
---@field language string Current language code
---@field languages string[] Server-side multi-language list (default: {}; not configured by this plugin)
---@field notes_languages string[] Picker language list (populated by config.setup; stripped from didChangeConfiguration)
---@field dictionary table<string, string[]> Words per language
---@field disabledRules table<string, string[]> Disabled rule IDs per language
---@field hiddenFalsePositives table<string, string[]> Hidden false positives per language
---@field spellCheck boolean Whether to perform grammar checks
---@field markdown table Settings for markdown parsing

---@class LtexPersistSpec
---@field setting string Settings key (e.g. "dictionary")
---@field arg_key string Command argument key (e.g. "words")
---@field msg string Notification message format (receives lang and joined items)

---@class LtexCheckDocumentParams
---@field uri? string

local ltex_data = require("notes.lsp.utils")
local ltex_path = vim.fs.joinpath(vim.fn.stdpath("data"), "ltex")
local marker = " [*]"

---@type table<string, LtexPersistSpec>
local specs = {
	["_ltex.addToDictionary"] = { setting = "dictionary", arg_key = "words", msg = "ltex: added to dictionary (%s): %s" },
	["_ltex.disableRules"] = { setting = "disabledRules", arg_key = "ruleIds", msg = "ltex: disabled rules (%s): %s" },
	["_ltex.hideFalsePositives"] = { setting = "hiddenFalsePositives", arg_key = "falsePositives", msg = "ltex: hid false positives (%s): %s" },
}

--- Noification helper for persisting items.
---@param msg string
---@param lang string
---@param items string[]
local function notify(msg, lang, items) vim.notify(string.format(msg, lang, table.concat(items, ", ")), vim.log.levels.INFO) end

--- Write a category's full data to a JSON file.
---@param name string Category name
---@param data table<string, string[]> Map of language to items
local function write(name, data)
	vim.fn.mkdir(ltex_path, "p")
	local ok, encoded = pcall(vim.json.encode, data)
	if not ok then return end
	vim.fn.writefile({ encoded }, vim.fs.joinpath(ltex_path, name .. ".json"))
end

--- Reload ltex settings after a change. Strips `languages` and `notes_languages` from
--- the payload so ltex never sees the picker list — preventing it from skipping the
--- document check when the current `language` is a member of `languages`.
---@param client vim.lsp.Client
---@param settings LtexSettings
local function reload_settings(client, settings)
	local payload = vim.tbl_extend("force", {}, settings)
	payload.languages = nil
	payload.notes_languages = nil
	client:notify("workspace/didChangeConfiguration", { settings = payload })
end

--- Get the ltex settings from a client.
---@param client vim.lsp.Client
---@return LtexSettings
local function get_settings(client)
	return client.config.settings.ltex --[[@as LtexSettings]]
end

--- Set the current language and notify + reload.
---@param client vim.lsp.Client
---@param settings LtexSettings
---@param lang string
local function set_language(client, settings, lang)
	settings.language = lang
	vim.notify("ltex: language set to " .. lang, vim.log.levels.INFO)
	reload_settings(client, settings)
end

--- Show the language picker over the configured language list.
--- Reads from `config.ltex_languages` (set by notes.config), then falls back to
--- `settings.notes_languages` or `settings.languages` for standalone use.
--- Does nothing (with a warning) when no languages are configured.
---@param client vim.lsp.Client
---@param settings LtexSettings
local function pick_language(client, settings)
	local cfg = package.loaded["notes.config"]
	local langs = (cfg and #cfg.ltex_languages > 0) and cfg.ltex_languages or settings.notes_languages or settings.languages or {}

	if #langs == 0 then
		vim.notify("ltex: no languages configured for picker", vim.log.levels.WARN)
		return
	end

	local items = vim.iter(langs):map(function(lang) return lang == settings.language and lang .. marker or lang end):totable()

	vim.ui.select(items, { prompt = "Language" }, function(choice)
		if not choice then return end
		local lang = choice:gsub(vim.pesc(marker) .. "$", "")
		set_language(client, settings, lang)
	end)
end

--- Request a re-check of the document from ltex.
---@param client vim.lsp.Client
---@param bufnr integer
---@param command lsp.Command
local function check_document(client, bufnr, command)
	local params = (command.arguments and command.arguments[1] or {}) --[[@as LtexCheckDocumentParams]]
	if type(params) ~= "table" then params = {} end
	params.uri = params.uri or vim.uri_from_bufnr(bufnr)
	client:request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { params } })
end

--- Append items to a persisted category and update the in-memory settings.
---@param category string Settings key (e.g. "dictionary")
---@param lang string Language code
---@param items string[] Items to append to the persisted list
---@param settings LtexSettings
local function persist(category, lang, items, settings)
	local existing = settings[category][lang] or {}
	vim.list_extend(existing, items)
	settings[category][lang] = existing
	write(category, settings[category])
end

--- Build the full _ltex.* command handler table for a buffer.
---@param client vim.lsp.Client
---@param bufnr integer
---@return table<string, function>
local function make_commands(client, bufnr)
	local settings = get_settings(client)

	local lang_list = settings.notes_languages or settings.languages or {}

	vim.iter(ltex_data.read_ltex_data()):each(function(setting, langs)
		vim.iter(lang_list):each(function(lang) settings[setting][lang] = langs[lang] or {} end)
	end)

	local commands = {}

	vim.iter(specs):each(function(cmd, spec)
		commands[cmd] = function(command)
			vim.iter(command.arguments[1][spec.arg_key]):each(function(lang, items)
				persist(spec.setting, lang, items, settings)
				notify(spec.msg, lang, items)
			end)

			reload_settings(client, settings)
		end
	end)

	commands["_ltex.pickLanguage"] = function() pick_language(client, settings) end
	commands["_ltex.checkDocument"] = function(command) check_document(client, bufnr, command) end

	return commands
end

return {
	cmd = { "ltex-ls-plus" },
	filetypes = { "markdown", "tex" },
	single_file_support = true,
	init_options = { client = "Neovim" },
	---@param client vim.lsp.Client
	---@param bufnr integer Buffer the LSP attached to
	on_attach = function(client, bufnr)
		vim.iter(make_commands(client, bufnr)):each(function(cmd, handler) vim.lsp.commands[cmd] = handler end)
	end,
	settings = {
		ltex = {
			language = "en-US",
			languages = {},
			dictionary = {},
			disabledRules = {},
			hiddenFalsePositives = {},
			spellCheck = true,
			markdown = { nodes = { Link = "dummy" } },
		},
	},
}
