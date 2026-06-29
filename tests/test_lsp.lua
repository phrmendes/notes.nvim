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

T["lsp"]["addToDictionary sends didChangeConfiguration"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	local client = attach(lsp_config)

	local before = #client._notified
	vim.lsp.commands["_ltex.addToDictionary"]({ arguments = { { words = { ["en-US"] = { "testword" } } } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["lsp"]["disableRules sends didChangeConfiguration"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	local client = attach(lsp_config)

	local before = #client._notified
	vim.lsp.commands["_ltex.disableRules"]({ arguments = { { ruleIds = { ["en-US"] = { "RULE_X" } } } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["lsp"]["pickLanguage falls back to vim.ui.input when languages is empty"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	attach(lsp_config)

	local input_called = false
	local select_called = false
	vim.ui.input = function() input_called = true end
	vim.ui.select = function() select_called = true end

	vim.lsp.commands["_ltex.pickLanguage"]({})

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

	vim.lsp.commands["_ltex.pickLanguage"]({})

	eq(select_called, true)
	eq(input_called, false)
end

T["lsp"]["notes.ltex_pick_language calls _ltex.pickLanguage command"] = function()
	local called = false
	vim.lsp.commands["_ltex.pickLanguage"] = function() called = true end

	require("notes").ltex_pick_language()

	eq(called, true)
end

T["lsp"]["notes.ltex_pick_language warns when command not registered"] = function()
	vim.lsp.commands["_ltex.pickLanguage"] = nil

	local warned = false
	local orig = vim.notify
	vim.notify = function(_, level)
		if level == vim.log.levels.WARN then warned = true end
	end

	require("notes").ltex_pick_language()

	vim.notify = orig
	eq(warned, true)
end

T["lsp"]["no textDocument/codeAction handler override after on_attach"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local lsp_config = loadfile(lsp_file)()
	local client = attach(lsp_config)

	eq(client.handlers["textDocument/codeAction"], nil)
end

return T
