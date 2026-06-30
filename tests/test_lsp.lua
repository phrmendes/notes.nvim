local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

T["lsp"] = new_set()

T["lsp"]["default enables both marksman and ltex_plus"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua(string.format([[require("notes.config").setup({ path = %q })]], temp_dir))

	local enabled = child.lua_get("_G.captured_lsp_enable")
	eq(#enabled, 2)
	eq(enabled[1], "marksman")
	eq(enabled[2], "ltex_plus")
end

T["lsp"]["can disable marksman"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { marksman = false } })]])

	local enabled = child.lua_get("_G.captured_lsp_enable")
	eq(#enabled, 1)
	eq(enabled[1], "ltex_plus")
end

T["lsp"]["can disable ltex_plus"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { ltex_plus = false } })]])

	local enabled = child.lua_get("_G.captured_lsp_enable")
	eq(#enabled, 1)
	eq(enabled[1], "marksman")
end

T["lsp"]["can disable both"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { marksman = false, ltex_plus = false } })]])

	eq(#child.lua_get("_G.captured_lsp_enable"), 0)
end

T["lsp"]["marksman.lua config file is valid"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "marksman.lua")
	eq(vim.uv.fs_stat(lsp_file) ~= nil, true)

	local config = loadfile(lsp_file)()
	eq(type(config), "table")
	eq(config.cmd[1], "marksman")
	eq(config.cmd[2], "server")
	eq(config.filetypes[1], "markdown")
	eq(config.single_file_support, true)
	eq(config.root_dir, nil)
	eq(type(config.root_markers), "table")
	eq(config.on_attach, nil)
end

T["lsp"]["marksman uses root_markers"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "marksman.lua")
	local config = loadfile(lsp_file)()

	eq(type(config.root_markers), "table")
	eq(vim.tbl_contains(config.root_markers, ".marksman.toml"), true)
	eq(vim.tbl_contains(config.root_markers, ".git"), true)
	eq(config.root_dir, nil)
end

T["lsp"]["ltex_plus.lua config file is valid"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	eq(vim.uv.fs_stat(lsp_file) ~= nil, true)

	local config = loadfile(lsp_file)()
	eq(type(config), "table")
	eq(config.cmd[1], "ltex-ls-plus")
	eq(config.filetypes[1], "markdown")
	eq(config.filetypes[2], "tex")
	eq(config.filetypes[3], "typst")
	eq(config.single_file_support, true)
	eq(type(config.on_attach), "function")
	eq(type(config.settings), "table")
	eq(type(config.settings.ltex), "table")
	eq(config.settings.ltex.language, "en-US")
	eq(type(config.settings.ltex.languages), "table")
	eq(type(config.settings.ltex.dictionary), "table")
	eq(config.settings.ltex.spellCheck, true)
end

T["lsp"]["ltex_plus uses single_file_support"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local config = loadfile(lsp_file)()

	eq(config.single_file_support, true)
	eq(config.root_dir, nil)
	eq(config.root_markers, nil)
end

local function make_client(lsp_config)
	local client = {
		config = lsp_config,
		handlers = {},
		_notified = {},
	}
	function client.notify(_, method, params) table.insert(client._notified, { method = method, params = params }) end
	function client.request() end
	return client
end

local function attach(lsp_config)
	local client = make_client(lsp_config)
	lsp_config.on_attach(client, 1)
	return client
end

local function run_ltex(cmd, arguments) vim.lsp.commands[cmd]({ arguments = { arguments or {} } }) end

T["lsp"]["addToDictionary sends didChangeConfiguration"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	local client = attach(lsp_config)

	local before = #client._notified
	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["lsp"]["disableRules notifies rule disabled"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	vim.notify = function(msg, _, _) table.insert(notified, msg) end

	run_ltex("_ltex.disableRules", { ruleIds = { ["en-US"] = { "RULE_X" } } })

	vim.notify = orig
	eq(#notified, 1)
	eq(notified[1]:find("RULE_X") ~= nil, true)
end

T["lsp"]["hideFalsePositives notifies false positive hidden"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	vim.notify = function(msg, _, _) table.insert(notified, msg) end

	run_ltex("_ltex.hideFalsePositives", { falsePositives = { ["en-US"] = { "fp-string" } } })

	vim.notify = orig
	eq(#notified, 1)
	eq(notified[1]:find("en%-US") ~= nil, true)
end

T["lsp"]["disableRules sends didChangeConfiguration"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	local client = attach(lsp_config)

	local before = #client._notified
	run_ltex("_ltex.disableRules", { ruleIds = { ["en-US"] = { "RULE_X" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["lsp"]["addToDictionary notifies words added"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	vim.notify = function(msg, _, _) table.insert(notified, msg) end

	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	vim.notify = orig
	eq(#notified, 1)
	eq(notified[1]:find("testword") ~= nil, true)
end

T["lsp"]["pickLanguage notifies language set via input"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	attach(lsp_config)

	local notified = {}
	local orig_notify = vim.notify
	local orig_input = vim.ui.input
	vim.notify = function(msg, _, _) table.insert(notified, msg) end
	vim.ui.input = function(_, cb) cb("pt-BR") end

	run_ltex("_ltex.pickLanguage")

	vim.notify = orig_notify
	vim.ui.input = orig_input
	eq(#notified, 1)
	eq(notified[1]:find("pt%-BR") ~= nil, true)
end

T["lsp"]["pickLanguage notifies language set via select"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	attach(lsp_config)

	local notified = {}
	local orig_notify = vim.notify
	local orig_select = vim.ui.select
	vim.notify = function(msg, _, _) table.insert(notified, msg) end
	vim.ui.select = function(_, _, cb) cb("pt-BR") end

	run_ltex("_ltex.pickLanguage")

	vim.notify = orig_notify
	vim.ui.select = orig_select
	eq(#notified, 1)
	eq(notified[1]:find("pt%-BR") ~= nil, true)
end

T["lsp"]["pickLanguage falls back to vim.ui.input when languages is empty"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	attach(lsp_config)

	local input_called = false
	local select_called = false
	vim.ui.input = function() input_called = true end
	vim.ui.select = function() select_called = true end

	run_ltex("_ltex.pickLanguage")

	eq(input_called, true)
	eq(select_called, false)
end

T["lsp"]["pickLanguage uses vim.ui.select when languages is set"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	attach(lsp_config)

	local input_called = false
	local select_called = false
	vim.ui.input = function() input_called = true end
	vim.ui.select = function() select_called = true end

	run_ltex("_ltex.pickLanguage")

	eq(select_called, true)
	eq(input_called, false)
end

T["lsp"]["notes.ltex_pick_language triggers the registered command"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	attach(lsp_config)

	local input_called = false
	local orig = vim.ui.input
	vim.ui.input = function() input_called = true end

	require("notes").ltex_pick_language()

	vim.ui.input = orig
	eq(input_called, true)
end

T["lsp"]["notes.ltex_pick_language warns when command not registered"] = function()
	local orig_commands = vim.lsp.commands
	vim.lsp.commands = {}

	local warned = false
	local orig_notify = vim.notify
	vim.notify = function(_, level)
		if level == vim.log.levels.WARN then warned = true end
	end

	require("notes").ltex_pick_language()

	vim.lsp.commands = orig_commands
	vim.notify = orig_notify
	eq(warned, true)
end

T["lsp"]["no textDocument/codeAction handler override after on_attach"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	local client = attach(lsp_config)

	eq(client.handlers["textDocument/codeAction"], nil)
end

T["lsp"]["read_persisted_data populates settings on attach"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	lsp_config.settings.ltex.languages = { "en-US" }

	local read_data = {
		dictionary = { ["en-US"] = { "foo", "bar" } },
		disabledRules = { ["en-US"] = { "RULE_X" } },
		hiddenFalsePositives = { ["en-US"] = { "fp" } },
	}

	local orig_fs_stat = vim.uv.fs_stat
	local orig_readfile = vim.fn.readfile
	vim.uv.fs_stat = function() return { type = "file" } end
	vim.fn.readfile = function(path, _, _)
		local content = "{}"
		for category, data in pairs(read_data) do
			if path and path:find(category) then content = vim.fn.json_encode(data) end
		end
		return { content }
	end

	attach(lsp_config)

	vim.uv.fs_stat = orig_fs_stat
	vim.fn.readfile = orig_readfile

	eq(lsp_config.settings.ltex.dictionary["en-US"][1], "foo")
	eq(lsp_config.settings.ltex.dictionary["en-US"][2], "bar")
	eq(lsp_config.settings.ltex.disabledRules["en-US"][1], "RULE_X")
	eq(lsp_config.settings.ltex.hiddenFalsePositives["en-US"][1], "fp")
end

T["lsp"]["pickLanguage strips the mark from the current language on select"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	lsp_config.settings.ltex.language = "en-US"
	local client = attach(lsp_config)

	local orig_select = vim.ui.select
	vim.ui.select = function(_, _, cb) cb("pt-BR [*]") end

	client._notified = {}
	run_ltex("_ltex.pickLanguage")

	vim.ui.select = orig_select
	eq(lsp_config.settings.ltex.language, "pt-BR")
end

return T
