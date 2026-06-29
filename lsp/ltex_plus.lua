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

---@class LtexPersistSpec
---@field setting string Settings key (e.g. "dictionary")
---@field arg_key string Command argument key (e.g. "words")
---@field notify? fun(lang: string, items: string[]) Optional notification after persist

---@type table<string, LtexPersistSpec>
local persist_specs = {
	["_ltex.addToDictionary"] = {
		setting = "dictionary",
		arg_key = "words",
		notify = function(lang, items) vim.notify(string.format("ltex: added to dictionary (%s): %s", lang, table.concat(items, ", ")), vim.log.levels.INFO) end,
	},
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

--- Notify the LSP client of a settings change.
---@param client vim.lsp.Client
---@param settings LtexSettings
local function notify(client, settings) client:notify("workspace/didChangeConfiguration", { settings = settings }) end

--- Append items to a persisted category and update the in-memory settings.
---@param category string Settings key (e.g. "dictionary")
---@param lang string Language code
---@param items string[] Items to append to the persisted list
---@param settings LtexSettings
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

		local commands = {
			["_ltex.spellCheck"] = function()
				settings.spellCheck = not settings.spellCheck
				notify(client, settings)
			end,
			["_ltex.pickLanguage"] = function()
				if #settings.languages == 0 then
					vim.ui.input({ prompt = "Language code: ", default = settings.language }, function(lang)
						if not lang or lang == "" then return end
						settings.language = lang
						vim.notify("ltex: language set to " .. lang, vim.log.levels.INFO)
						notify(client, settings)
					end)
					return
				end
				local items = vim.iter(settings.languages):map(function(lang) return lang == settings.language and lang .. current_lang_mark or lang end):totable()
				vim.ui.select(items, { prompt = "Language" }, function(choice)
					if not choice then return end
					local lang = choice:gsub(vim.pesc(current_lang_mark) .. "$", "")
					settings.language = lang
					vim.notify("ltex: language set to " .. lang, vim.log.levels.INFO)
					notify(client, settings)
				end)
			end,
			["_ltex.checkDocument"] = function(command)
				---@class LtexCheckDocumentParams
				---@field uri? string
				local params = command.arguments and command.arguments[1]
				if type(params) ~= "table" then params = {} end
				---@cast params LtexCheckDocumentParams
				params.uri = params.uri or vim.uri_from_bufnr(bufnr)
				client:request("workspace/executeCommand", { command = "_ltex.checkDocument", arguments = { params } })
			end,
		}

		vim.iter(persist_specs):each(function(cmd, spec)
			commands[cmd] = function(command)
				vim.iter(command.arguments[1][spec.arg_key]):each(function(lang, items)
					persist(spec.setting, lang, items, settings)
					if spec.notify then spec.notify(lang, items) end
				end)
				notify(client, settings)
			end
		end)

		vim.iter(commands):each(function(cmd, handler) vim.lsp.commands[cmd] = handler end)

		notify(client, settings)
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
