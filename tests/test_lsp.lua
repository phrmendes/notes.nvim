local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local vimx = vim --[[@as any]]
local vui = vim.ui --[[@as any]]
local vfn = vim.fn --[[@as any]]
local vuv = vim.uv --[[@as any]]

local child, T = utils.new_child_set()

local function load_ltex() return loadfile(vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua"))() end

T["lsp"] = new_set({
	hooks = {
		pre_case = function()
			_G.orig_writefile = vim.fn.writefile
			_G.orig_mkdir = vim.fn.mkdir
			vfn.writefile = function() return 0 end
			vfn.mkdir = function() return 1 end
		end,
		post_case = function()
			vfn.writefile = _G.orig_writefile
			vfn.mkdir = _G.orig_mkdir
		end,
	},
})

T["lsp"]["default enables both marksman and ltex_plus"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua(string.format([[require("notes.config").setup({ path = %q })]], temp_dir))

	local enabled = child.lua_get("_G.captured_lsp_enable")
	eq(#enabled, 2)
	eq(vim.tbl_contains(enabled, "marksman"), true)
	eq(vim.tbl_contains(enabled, "ltex_plus"), true)
end

T["lsp"]["can disable marksman"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { marksman = { enabled = false } } })]])

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

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { ltex_plus = { enabled = false } } })]])

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

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { marksman = { enabled = false }, ltex_plus = { enabled = false } } })]])

	eq(#child.lua_get("_G.captured_lsp_enable"), 0)
end

T["lsp"]["lsp = false disables all servers"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = false })]])

	eq(#child.lua_get("_G.captured_lsp_enable"), 0)
end

T["lsp"]["can configure ltex_plus languages via setup"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua([[
		_G.captured_lsp_config = nil
		_G.captured_lsp_enable = {}
		vim.lsp.config = function(name, opts) _G.captured_lsp_config = { name = name, opts = opts } end
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua(string.format([[require("notes.config").setup({ path = %q, lsp = { marksman = { enabled = false }, ltex_plus = { enabled = true, languages = { default = "en-US", additionals = { "pt-BR", "fr-FR" } } } } })]], temp_dir))

	local captured = child.lua_get("_G.captured_lsp_config")
	local langs = captured.opts.settings.ltex.languages
	eq(captured.name, "ltex_plus")
	eq(captured.opts.settings.ltex.language, "en-US")
	eq(vim.tbl_contains(langs, "en-US"), true)
	eq(vim.tbl_contains(langs, "pt-BR"), true)
	eq(vim.tbl_contains(langs, "fr-FR"), true)
	eq(#langs, 3)
	eq(captured.opts.settings.ltex.notes_languages, nil)
	eq(#child.lua_get("_G.captured_lsp_enable"), 1)
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

	local config = load_ltex()
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
	local config = load_ltex()

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
	lsp_config.on_attach(client --[[@as any]], 1)
	return client
end

local function run_ltex(cmd, arguments)
	local handler = vim.lsp.commands[cmd] --[[@as fun(a: any)]]
	handler({ arguments = { arguments or {} } })
end

T["lsp"]["addToDictionary sends didChangeConfiguration"] = function()
	local lsp_config = load_ltex()
	local client = attach(lsp_config)

	local before = #client._notified
	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["lsp"]["reload_settings does not send languages to ltex"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	local client = attach(lsp_config)

	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	local notif = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(notif[1].params.settings.languages, nil)
end

T["lsp"]["disableRules notifies rule disabled"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	vimx.notify = function(msg, _, _) table.insert(notified, msg) end

	run_ltex("_ltex.disableRules", { ruleIds = { ["en-US"] = { "RULE_X" } } })

	vimx.notify = orig
	eq(#notified, 1)
	eq(notified[1]:find("RULE_X") ~= nil, true)
end

T["lsp"]["hideFalsePositives notifies false positive hidden"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	vimx.notify = function(msg, _, _) table.insert(notified, msg) end

	run_ltex("_ltex.hideFalsePositives", { falsePositives = { ["en-US"] = { "fp-string" } } })

	vimx.notify = orig
	eq(#notified, 1)
	eq(notified[1]:find("en%-US") ~= nil, true)
end

T["lsp"]["disableRules sends didChangeConfiguration"] = function()
	local lsp_config = load_ltex()
	local client = attach(lsp_config)

	local before = #client._notified
	run_ltex("_ltex.disableRules", { ruleIds = { ["en-US"] = { "RULE_X" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["lsp"]["addToDictionary notifies words added"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	vimx.notify = function(msg, _, _) table.insert(notified, msg) end

	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	vimx.notify = orig
	eq(#notified, 1)
	eq(notified[1]:find("testword") ~= nil, true)
end

T["lsp"]["pickLanguage notifies language set via select"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	attach(lsp_config)

	local notified = {}
	local orig_notify = vim.notify
	local orig_select = vim.ui.select
	vimx.notify = function(msg, _, _) table.insert(notified, msg) end
	vui.select = function(_, _, cb) cb("pt-BR") end

	run_ltex("_ltex.pickLanguage")

	vimx.notify = orig_notify
	vui.select = orig_select
	eq(#notified, 1)
	eq(notified[1]:find("pt%-BR") ~= nil, true)
end

T["lsp"]["pickLanguage warns when no languages configured"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local warned = false
	local select_called = false
	local orig_notify = vim.notify
	vimx.notify = function(_, level, _)
		if level == vim.log.levels.WARN then warned = true end
	end
	vui.select = function() select_called = true end

	run_ltex("_ltex.pickLanguage")

	vimx.notify = orig_notify
	eq(warned, true)
	eq(select_called, false)
end

T["lsp"]["pickLanguage uses vim.ui.select when languages is set"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	attach(lsp_config)

	local input_called = false
	local select_called = false
	vui.input = function() input_called = true end
	vui.select = function() select_called = true end

	run_ltex("_ltex.pickLanguage")

	eq(select_called, true)
	eq(input_called, false)
end

T["lsp"]["notes.ltex_pick_language triggers the registered command"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US" }
	attach(lsp_config)

	local select_called = false
	local orig_select = vim.ui.select
	vui.select = function() select_called = true end

	require("notes").ltex_pick_language()

	vui.select = orig_select
	eq(select_called, true)
end

T["lsp"]["notes.ltex_pick_language warns when command not registered"] = function()
	local orig_commands = vim.lsp.commands
	vim.lsp.commands = {}

	local warned = false
	local orig_notify = vim.notify
	vimx.notify = function(_, level, _)
		if level == vim.log.levels.WARN then warned = true end
	end

	require("notes").ltex_pick_language()

	vim.lsp.commands = orig_commands
	vimx.notify = orig_notify
	eq(warned, true)
end

T["lsp"]["no textDocument/codeAction handler override after on_attach"] = function()
	local lsp_config = load_ltex()
	local client = attach(lsp_config)

	eq(client.handlers["textDocument/codeAction"], nil)
end

T["lsp"]["read_persisted_data populates settings on attach"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US" }

	local read_data = {
		dictionary = { ["en-US"] = { "foo", "bar" } },
		disabledRules = { ["en-US"] = { "RULE_X" } },
		hiddenFalsePositives = { ["en-US"] = { "fp" } },
	}

	local orig_fs_stat = vim.uv.fs_stat
	local orig_readfile = vim.fn.readfile
	vuv.fs_stat = function() return { type = "file" } end
	vfn.readfile = function(path, _, _)
		local content = "{}"
		for category, data in pairs(read_data) do
			if path and path:find(category) then content = vim.fn.json_encode(data) end
		end
		return { content }
	end

	attach(lsp_config)

	vuv.fs_stat = orig_fs_stat
	vfn.readfile = orig_readfile

	eq(lsp_config.settings.ltex.dictionary["en-US"][1], "foo")
	eq(lsp_config.settings.ltex.dictionary["en-US"][2], "bar")
	eq(lsp_config.settings.ltex.disabledRules["en-US"][1], "RULE_X")
	eq(lsp_config.settings.ltex.hiddenFalsePositives["en-US"][1], "fp")
end

T["lsp"]["pickLanguage strips the mark from the current language on select"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	lsp_config.settings.ltex.language = "en-US"
	local client = attach(lsp_config)

	local orig_select = vim.ui.select
	vui.select = function(_, _, cb) cb("pt-BR [*]") end

	client._notified = {}
	run_ltex("_ltex.pickLanguage")

	vui.select = orig_select
	eq(lsp_config.settings.ltex.language, "pt-BR")
end

return T
