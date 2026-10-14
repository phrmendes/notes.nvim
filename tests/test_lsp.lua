local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

local patch = utils.patch
local function load_ltex() return loadfile(vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua"))() end
local function load_marksman() return loadfile(vim.fs.joinpath(vim.uv.cwd(), "lsp", "marksman.lua"))() end

--- Start real marksman without a workspace folder and return the file-operation
--- globs it advertises. That mode is what used to produce `**/*.{}`.
---@param ch MiniTest.child
---@return string[]
local function marksman_globs(ch)
	return ch.lua([[
		local cfg = vim.deepcopy(vim.lsp.config["marksman"])
		cfg.root_dir = false

		local id = vim.lsp.start(cfg)
		vim.wait(10000, function()
			local c = vim.lsp.get_client_by_id(id)
			return c ~= nil and c.initialized
		end, 100)

		local client = assert(vim.lsp.get_client_by_id(id), "marksman did not start")
		local ops = vim.tbl_get(client.server_capabilities, "workspace", "fileOperations") or {}

		local globs = {}
		for _, spec in pairs(ops) do
			for _, filter in ipairs(spec.filters or {}) do
				table.insert(globs, filter.pattern.glob)
			end
		end

		client:stop()
		return globs
	]])
end

local function make_client(lsp_config)
	local client = {
		config = lsp_config,
		handlers = {},
		notified = {},
	}

	function client.notify(_, method, params) table.insert(client.notified, { method = method, params = params }) end
	function client.request() end
	return client
end

local function attach(lsp_config)
	local client = make_client(lsp_config)
	lsp_config.on_attach(client --[[@as vim.lsp.Client]], 1)
	return client
end

local function run_ltex(cmd, arguments)
	local handler = vim.lsp.commands[cmd] --[[@as fun(command: table)]]
	handler({ arguments = { arguments or {} } })
end

T["lsp setup"] = new_set()

T["lsp setup"]["ltex_plus never auto-enables"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua(string.format([[require("notes.config").setup({ path = %q })]], temp_dir))

	local enabled = child.lua_get("_G.captured_lsp_enable")
	eq(#enabled, 1)
	eq(enabled[1], "marksman")
end

T["lsp setup"]["can disable marksman (ltex_plus stays detached)"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { marksman = { enabled = false } } })]])

	local enabled = child.lua_get("_G.captured_lsp_enable")
	eq(#enabled, 0)
end

T["lsp setup"]["can disable ltex_plus"] = function()
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

T["lsp setup"]["can disable both"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { marksman = { enabled = false }, ltex_plus = { enabled = false } } })]])

	eq(#child.lua_get("_G.captured_lsp_enable"), 0)
end

T["lsp setup"]["lsp = false disables all servers"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = {}
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = false })]])

	eq(#child.lua_get("_G.captured_lsp_enable"), 0)
end

T["lsp setup"]["can configure ltex_plus languages via setup"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua([[
		_G.captured_lsp_config = nil
		_G.captured_lsp_enable = {}
		vim.lsp.config = function(name, opts) _G.captured_lsp_config = { name = name, opts = opts } end
		vim.lsp.enable = function(name) table.insert(_G.captured_lsp_enable, name) end
	]])

	child.lua(string.format([[require("notes.config").setup({ path = %q, lsp = { marksman = { enabled = false }, ltex_plus = { enabled = true, languages = { default = "en-US", additionals = { "pt-BR", "fr-FR" } } } } })]], temp_dir))

	local captured = child.lua_get("_G.captured_lsp_config")
	local notes_langs = captured.opts.settings.ltex.notes_languages
	local cfg_langs = child.lua_get("require('notes.config').ltex_languages")
	eq(captured.name, "ltex_plus")
	eq(captured.opts.settings.ltex.language, "en-US")
	eq(captured.opts.settings.ltex.languages, nil)
	eq(vim.tbl_contains(notes_langs, "en-US"), true)
	eq(vim.tbl_contains(notes_langs, "pt-BR"), true)
	eq(vim.tbl_contains(notes_langs, "fr-FR"), true)
	eq(#notes_langs, 3)
	eq(vim.tbl_contains(cfg_langs, "en-US"), true)
	eq(#cfg_langs, 3)
	eq(#child.lua_get("_G.captured_lsp_enable"), 0)
end

T["lsp config"] = new_set()

T["lsp config"]["marksman.lua is valid"] = function()
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

T["lsp config"]["marksman uses root_markers"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "marksman.lua")
	local config = loadfile(lsp_file)()

	eq(type(config.root_markers), "table")
	eq(vim.tbl_contains(config.root_markers, ".marksman.toml"), true)
	eq(vim.tbl_contains(config.root_markers, ".git"), true)
	eq(config.root_dir, nil)
end

T["lsp config"]["marksman on_init repairs the empty file-operation glob"] = function()
	local config = load_marksman()

	local client = {
		server_capabilities = {
			workspace = {
				fileOperations = {
					didCreate = { filters = { { pattern = { glob = "**/*.{}" } } } },
					didDelete = { filters = { { pattern = { glob = "**/*.{}" } } } },
				},
			},
		},
	}

	config.on_init(client)

	eq(client.server_capabilities.workspace.fileOperations.didCreate.filters[1].pattern.glob, "**/*.{md,markdown}")
	eq(client.server_capabilities.workspace.fileOperations.didDelete.filters[1].pattern.glob, "**/*.{md,markdown}")
end

T["lsp config"]["marksman on_init keeps a valid glob"] = function()
	local config = load_marksman()

	local client = { server_capabilities = { workspace = { fileOperations = { didDelete = { filters = { { pattern = { glob = "**/*.{md}" } } } } } } } }
	config.on_init(client)

	eq(client.server_capabilities.workspace.fileOperations.didDelete.filters[1].pattern.glob, "**/*.{md}")
end

T["lsp config"]["marksman on_init tolerates missing capabilities"] = function()
	local config = load_marksman()

	eq(pcall(config.on_init, { server_capabilities = {} }), true)
end

-- Regression test for the `**/*.{}` workaround in `lsp/marksman.lua`.
T["lsp config"]["marksman globs are valid with a real server"] = function()
	if not child.lua_get([[vim.fn.executable("marksman") == 1]]) then MiniTest.skip("marksman not installed") end

	local globs = marksman_globs(child)
	local invalid = vim.iter(globs):filter(function(glob) return not pcall(vim.glob.to_lpeg, glob) end):totable()

	eq(#globs > 0, true)
	eq(invalid, {})
end

T["lsp config"]["ltex_plus.lua is valid"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	eq(vim.uv.fs_stat(lsp_file) ~= nil, true)

	local config = load_ltex()
	eq(type(config), "table")
	eq(config.cmd[1], "ltex-ls-plus")
	eq(config.filetypes[1], "markdown")
	eq(config.filetypes[2], "tex")
	eq(config.single_file_support, true)
	eq(type(config.on_attach), "function")
	eq(type(config.settings), "table")
	eq(type(config.settings.ltex), "table")
	eq(config.settings.ltex.language, "en-US")
	eq(type(config.settings.ltex.languages), "table")
	eq(type(config.settings.ltex.dictionary), "table")
	eq(config.settings.ltex.spellCheck, true)
end

T["lsp config"]["ltex_plus uses single_file_support"] = function()
	local config = load_ltex()

	eq(config.single_file_support, true)
	eq(config.root_dir, nil)
	eq(config.root_markers, nil)
end

T["lsp config"]["health check runs without error"] = function()
	local ok = child.lua_get([[pcall(function() require("notes.health").check() end)]])
	eq(ok, true)
end

T["ltex commands"] = new_set({
	hooks = {
		pre_case = function()
			_G.orig_writefile = vim.fn.writefile
			_G.orig_mkdir = vim.fn.mkdir
			patch(vim.fn, "writefile", function() return 0 end)
			patch(vim.fn, "mkdir", function() return 1 end)
		end,
		post_case = function()
			patch(vim.fn, "writefile", _G.orig_writefile)
			patch(vim.fn, "mkdir", _G.orig_mkdir)
		end,
	},
})

T["ltex commands"]["addToDictionary sends didChangeConfiguration"] = function()
	local lsp_config = load_ltex()
	local client = attach(lsp_config)

	local before = #client.notified
	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client.notified)
	eq(#after_calls > before, true)
end

T["ltex commands"]["reload_settings does not send languages to ltex"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	local client = attach(lsp_config)

	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	local notif = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client.notified)
	eq(notif[1].params.settings.languages, nil)
end

vim
	.iter({
		{ cmd = "_ltex.disableRules", arg = "ruleIds", val = "RULE_X", msg = "RULE_X" },
		{ cmd = "_ltex.hideFalsePositives", arg = "falsePositives", val = "fp-string", msg = "en%-US" },
		{ cmd = "_ltex.addToDictionary", arg = "words", val = "testword", msg = "testword" },
	})
	:each(function(c)
		T["ltex commands"][string.format("notifies on %s", c.cmd)] = function()
			local lsp_config = load_ltex()
			attach(lsp_config)

			local notified = {}
			local orig = vim.notify
			patch(vim, "notify", function(msg, _, _) table.insert(notified, msg) end)

			run_ltex(c.cmd, { [c.arg] = { ["en-US"] = { c.val } } })

			patch(vim, "notify", orig)
			eq(#notified, 1)
			eq(notified[1]:find(c.msg) ~= nil, true)
		end
	end)

T["ltex commands"]["disableRules sends didChangeConfiguration"] = function()
	local lsp_config = load_ltex()
	local client = attach(lsp_config)

	local before = #client.notified
	run_ltex("_ltex.disableRules", { ruleIds = { ["en-US"] = { "RULE_X" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client.notified)
	eq(#after_calls > before, true)
end

T["ltex commands"]["no textDocument/codeAction handler override after on_attach"] = function()
	local lsp_config = load_ltex()
	local client = attach(lsp_config)

	eq(client.handlers["textDocument/codeAction"], nil)
end

T["ltex commands"]["read_persisted_data populates settings on attach"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US" }

	local read_data = {
		dictionary = { ["en-US"] = { "foo", "bar" } },
		disabledRules = { ["en-US"] = { "RULE_X" } },
		hiddenFalsePositives = { ["en-US"] = { "fp" } },
	}

	local orig_fs_stat = vim.uv.fs_stat
	local orig_readfile = vim.fn.readfile
	patch(vim.uv, "fs_stat", function() return { type = "file" } end)
	patch(vim.fn, "readfile", function(path, _, _)
		local content = "{}"
		for category, data in pairs(read_data) do
			if path and path:find(category) then content = vim.fn.json_encode(data) end
		end
		return { content }
	end)

	attach(lsp_config)

	patch(vim.uv, "fs_stat", orig_fs_stat)
	patch(vim.fn, "readfile", orig_readfile)

	eq(lsp_config.settings.ltex.dictionary["en-US"][1], "foo")
	eq(lsp_config.settings.ltex.dictionary["en-US"][2], "bar")
	eq(lsp_config.settings.ltex.disabledRules["en-US"][1], "RULE_X")
	eq(lsp_config.settings.ltex.hiddenFalsePositives["en-US"][1], "fp")
end

T["ltex commands"]["pickLanguage notifies language set via select"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	attach(lsp_config)

	local notified = {}
	local orig_notify = vim.notify
	local orig_select = vim.ui.select
	patch(vim, "notify", function(msg, _, _) table.insert(notified, msg) end)
	patch(vim.ui, "select", function(_, _, cb) cb("pt-BR") end)

	run_ltex("_ltex.pickLanguage")

	patch(vim, "notify", orig_notify)
	patch(vim.ui, "select", orig_select)
	eq(#notified, 1)
	eq(notified[1]:find("pt%-BR") ~= nil, true)
end

T["ltex commands"]["pickLanguage warns when no languages configured"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local warned = false
	local select_called = false
	local orig_notify = vim.notify
	local orig_select = vim.ui.select
	patch(vim, "notify", function(_, level, _)
		if level == vim.log.levels.WARN then warned = true end
	end)
	patch(vim.ui, "select", function() select_called = true end)

	run_ltex("_ltex.pickLanguage")

	patch(vim, "notify", orig_notify)
	patch(vim.ui, "select", orig_select)
	eq(warned, true)
	eq(select_called, false)
end

T["ltex commands"]["pickLanguage uses vim.ui.select when languages is set"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	attach(lsp_config)

	local input_called = false
	local select_called = false
	local orig_input = vim.ui.input
	local orig_select = vim.ui.select
	patch(vim.ui, "input", function() input_called = true end)
	patch(vim.ui, "select", function() select_called = true end)

	run_ltex("_ltex.pickLanguage")

	patch(vim.ui, "input", orig_input)
	patch(vim.ui, "select", orig_select)
	eq(select_called, true)
	eq(input_called, false)
end

T["ltex commands"]["pickLanguage strips the mark from the current language on select"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	lsp_config.settings.ltex.language = "en-US"
	local client = attach(lsp_config)

	local orig_select = vim.ui.select
	patch(vim.ui, "select", function(_, _, cb) cb("pt-BR [*]") end)

	client.notified = {}
	run_ltex("_ltex.pickLanguage")

	patch(vim.ui, "select", orig_select)
	eq(lsp_config.settings.ltex.language, "pt-BR")
end

T["ltex commands"]["notes.ltex_pick_language triggers the registered command"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US" }
	attach(lsp_config)

	local select_called = false
	local orig_select = vim.ui.select
	patch(vim.ui, "select", function() select_called = true end)

	require("notes").ltex_pick_language()

	patch(vim.ui, "select", orig_select)
	eq(select_called, true)
end

T["ltex commands"]["notes.ltex_pick_language warns when command not registered"] = function()
	local orig_commands = vim.lsp.commands
	patch(vim.lsp, "commands", {})

	local warned = false
	local orig_notify = vim.notify
	patch(vim, "notify", function(_, level, _)
		if level == vim.log.levels.WARN then warned = true end
	end)

	require("notes").ltex_pick_language()

	patch(vim.lsp, "commands", orig_commands)
	patch(vim, "notify", orig_notify)
	eq(warned, true)
end

T["notes lsp code actions"] = new_set()

local function load_notes_lsp() return require("notes.lsp") end

T["notes lsp code actions"]["returns Pick language when ltex is attached"] = function()
	local orig_get_clients = vim.lsp.get_clients
	patch(vim.lsp, "get_clients", function(_) return { { name = "ltex_plus" } } end)

	local notes_lsp = load_notes_lsp()
	---@type lsp.CodeAction[]
	local captured = {}
	notes_lsp.handlers[vim.lsp.protocol.Methods.textDocument_codeAction]({}, function(_, result) captured = result end)

	patch(vim.lsp, "get_clients", orig_get_clients)

	eq(#captured, 2)
	local titles = vim.tbl_map(function(a) return a.title end, captured)
	eq(vim.tbl_contains(titles, "Pick language"), true)
	eq(vim.tbl_contains(titles, "Disable spellcheck (current: enabled)"), true)
end

T["notes lsp code actions"]["does not return Pick language when ltex is detached"] = function()
	local orig_get_clients = vim.lsp.get_clients
	patch(vim.lsp, "get_clients", function(_) return {} end)

	local notes_lsp = load_notes_lsp()
	---@type lsp.CodeAction[]
	local captured = {}
	notes_lsp.handlers[vim.lsp.protocol.Methods.textDocument_codeAction]({}, function(_, result) captured = result end)

	patch(vim.lsp, "get_clients", orig_get_clients)

	eq(#captured, 1)
	eq(captured[1].title, "Enable spellcheck (current: disabled)")
end

return T
