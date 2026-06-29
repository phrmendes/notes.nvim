local ltex_path = vim.fs.joinpath(vim.fn.stdpath("data"), "ltex")
local current_lang_mark = " [*]"

---@class LtexSettings
---@field language string Current language code
---@field languages string[] Available languages for cycling
---@field dictionary table<string, string[]> Words per language
---@field disabledRules table<string, string[]> Disabled rule IDs per language
---@field hiddenFalsePositives table<string, string[]> Hidden false positives per language
---@field spellCheck boolean Whether to perform grammar checks
---@field markdown table Settings for markdown parsing

local methods = {
	["_ltex.addToDictionary"] = { setting = "dictionary", arg_key = "words" },
	["_ltex.disableRules"] = { setting = "disabledRules", arg_key = "ruleIds" },
	["_ltex.hideFalsePositives"] = { setting = "hiddenFalsePositives", arg_key = "falsePositives" },
}

--- Read a category's persisted data from a JSON file.
---@param name string Category name (e.g. "dictionary")
---@return table<string, string[]> Map of language to items
local function load_category(name)
	local path = vim.fs.joinpath(ltex_path, name .. ".json")
	if not vim.uv.fs_stat(path) then return {} end

	local content = vim.fn.readfile(path)
	if not content[1] then return {} end

	local ok, data = pcall(vim.json.decode, content[1])
	if not ok or type(data) ~= "table" then return {} end

	return data
end

--- Write a category's full data to a JSON file.
---@param name string Category name
---@param data table<string, string[]> Map of language to items
local function save_category(name, data)
	vim.fn.mkdir(ltex_path, "p")
	local ok, encoded = pcall(vim.json.encode, data)
	if not ok then return end
	vim.fn.writefile({ encoded }, vim.fs.joinpath(ltex_path, name .. ".json"))
end

--- Append items to a persisted category and update the in-memory settings.
---@param category string Settings key (e.g. "dictionary")
---@param lang string Language code
---@param items string[] Items to append to the persisted list
---@param settings table The ltex settings table
local function persist(category, lang, items, settings)
	local existing = settings[category][lang] or {}
	vim.list_extend(existing, items)
	settings[category][lang] = existing
	save_category(category, settings[category])
end

return {
	cmd = { "ltex-ls-plus" },
	filetypes = { "markdown", "tex", "typst" },
	single_file_support = true,
	init_options = {
		client = "Neovim",
		customCapabilities = {
			workspaceSpecificConfiguration = true,
		},
	},
	---@param client vim.lsp.Client
	---@param bufnr integer Buffer the LSP attached to
	on_attach = function(client, bufnr)
		---@type LtexSettings
		local settings = client.config.settings.ltex

		vim.iter({ "dictionary", "disabledRules", "hiddenFalsePositives" }):each(function(category)
			local data = load_category(category)
			vim.iter(settings.languages):each(function(lang) settings[category][lang] = data[lang] or {} end)
		end)

		vim.iter(methods):each(function(cmd, spec)
			vim.lsp.commands[cmd] = function(command)
				vim.iter(command.arguments[1][spec.arg_key]):each(function(lang, items) persist(spec.setting, lang, items, settings) end)
			end
		end)

		vim.lsp.commands["_ltex.spellCheck"] = function()
			settings.spellCheck = not settings.spellCheck
			client:notify("workspace/didChangeConfiguration", { settings = settings })
		end

		vim.lsp.commands["_ltex.pickLanguage"] = function()
			local items = vim.iter(settings.languages):map(function(lang) return lang == settings.language and lang .. current_lang_mark or lang end):totable()

			vim.ui.select(items, { prompt = "Language" }, function(choice)
				if not choice then return end
				local lang = choice:gsub(vim.pesc(current_lang_mark) .. "$", "")
				settings.language = lang
				client:notify("workspace/didChangeConfiguration", { settings = settings })
			end)
		end

		vim.lsp.commands["_ltex.checkDocument"] = function(command)
			local params = command.arguments and command.arguments[1]
			if type(params) ~= "table" then params = {} end

			params.uri = params.uri or vim.uri_from_bufnr(bufnr)
			client:request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { params } })
		end

		local original_code_action = client.handlers["textDocument/codeAction"] or vim.lsp.handlers["textDocument/codeAction"]

		client.handlers["textDocument/codeAction"] = function(err, result, ctx, config)
			local actions = original_code_action(err, result, ctx, config) or {}
			table.insert(actions, { title = "Pick language", command = { command = "_ltex.pickLanguage", arguments = {} } })
			return actions
		end

		client:notify("workspace/didChangeConfiguration", { settings = settings })
	end,
	settings = {
		ltex = {
			language = "en-US",
			languages = { "en-US", "pt-BR", "es-ES" },
			dictionary = {},
			disabledRules = {},
			hiddenFalsePositives = {},
			spellCheck = true,
			markdown = { nodes = { Link = "dummy" } },
		},
	},
}
