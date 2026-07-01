local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

local function patch(t, k, v) rawset(t, k, v) end
local function load_ltex() return loadfile(vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua"))() end

-- ltex command test helpers

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
	lsp_config.on_attach(client --[[@as vim.lsp.Client]], 1)
	return client
end

local function run_ltex(cmd, arguments)
	local handler = vim.lsp.commands[cmd] --[[@as fun(command: table)]]
	handler({ arguments = { arguments or {} } })
end

-- injection test helpers

local original_buf_request_all
local original_get_client_by_id

local function restore_all()
	require("notes.lsp").reset_code_actions()
	if original_buf_request_all then
		patch(vim.lsp, "buf_request_all", original_buf_request_all)
		original_buf_request_all = nil
	end
	if original_get_client_by_id then
		patch(vim.lsp, "get_client_by_id", original_get_client_by_id)
		original_get_client_by_id = nil
	end
end

---@param languages string[]|nil
local function mock_client(languages)
	return {
		name = "ltex_plus",
		config = { settings = { ltex = { languages = languages or { "en-US" } } } },
	}
end

---@param result_actions table[]
local function install_test_request_mock(result_actions)
	original_buf_request_all = vim.lsp.buf_request_all
	patch(vim.lsp, "buf_request_all", function(_, method, _, callback)
		if method == "textDocument/codeAction" then callback({
			[1] = { result = result_actions, context = { client_id = 1 } },
		}) end
	end)
end

-- ── lsp setup ────────────────────────────────────────────────────────────────

T["lsp setup"] = new_set()

T["lsp setup"]["default enables both marksman and ltex_plus"] = function()
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

T["lsp setup"]["can disable marksman"] = function()
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

-- ── lsp config ───────────────────────────────────────────────────────────────

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

T["lsp config"]["ltex_plus.lua is valid"] = function()
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

T["lsp config"]["ltex_plus uses single_file_support"] = function()
	local config = load_ltex()

	eq(config.single_file_support, true)
	eq(config.root_dir, nil)
	eq(config.root_markers, nil)
end

-- ── ltex commands ─────────────────────────────────────────────────────────────

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

	local before = #client._notified
	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["ltex commands"]["reload_settings does not send languages to ltex"] = function()
	local lsp_config = load_ltex()
	lsp_config.settings.ltex.languages = { "en-US", "pt-BR" }
	local client = attach(lsp_config)

	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	local notif = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(notif[1].params.settings.languages, nil)
end

T["ltex commands"]["disableRules notifies rule disabled"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	patch(vim, "notify", function(msg, _, _) table.insert(notified, msg) end)

	run_ltex("_ltex.disableRules", { ruleIds = { ["en-US"] = { "RULE_X" } } })

	patch(vim, "notify", orig)
	eq(#notified, 1)
	eq(notified[1]:find("RULE_X") ~= nil, true)
end

T["ltex commands"]["hideFalsePositives notifies false positive hidden"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	patch(vim, "notify", function(msg, _, _) table.insert(notified, msg) end)

	run_ltex("_ltex.hideFalsePositives", { falsePositives = { ["en-US"] = { "fp-string" } } })

	patch(vim, "notify", orig)
	eq(#notified, 1)
	eq(notified[1]:find("en%-US") ~= nil, true)
end

T["ltex commands"]["disableRules sends didChangeConfiguration"] = function()
	local lsp_config = load_ltex()
	local client = attach(lsp_config)

	local before = #client._notified
	run_ltex("_ltex.disableRules", { ruleIds = { ["en-US"] = { "RULE_X" } } })

	local after_calls = vim.tbl_filter(function(n) return n.method == "workspace/didChangeConfiguration" end, client._notified)
	eq(#after_calls > before, true)
end

T["ltex commands"]["addToDictionary notifies words added"] = function()
	local lsp_config = load_ltex()
	attach(lsp_config)

	local notified = {}
	local orig = vim.notify
	patch(vim, "notify", function(msg, _, _) table.insert(notified, msg) end)

	run_ltex("_ltex.addToDictionary", { words = { ["en-US"] = { "testword" } } })

	patch(vim, "notify", orig)
	eq(#notified, 1)
	eq(notified[1]:find("testword") ~= nil, true)
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

	client._notified = {}
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

-- ── ltex injection ────────────────────────────────────────────────────────────

T["ltex injection"] = new_set()

T["ltex injection"]["setup_code_actions patches vim.lsp.buf_request_all"] = function()
	restore_all()
	local notes_lsp = require("notes.lsp")

	local original = vim.lsp.buf_request_all
	notes_lsp.setup_code_actions()

	eq(vim.lsp.buf_request_all ~= original, true)

	restore_all()
end

T["ltex injection"]["setup_code_actions is idempotent"] = function()
	restore_all()
	local notes_lsp = require("notes.lsp")

	notes_lsp.setup_code_actions()
	local patched = vim.lsp.buf_request_all
	notes_lsp.setup_code_actions()

	eq(vim.lsp.buf_request_all, patched)

	restore_all()
end

T["ltex injection"]["injects Pick language for ltex_plus client"] = function()
	restore_all()
	local notes_lsp = require("notes.lsp")

	original_get_client_by_id = vim.lsp.get_client_by_id
	patch(vim.lsp, "get_client_by_id", function() return mock_client({ "en-US", "pt-BR" }) end)

	install_test_request_mock({ { title = "server action" } })
	notes_lsp.setup_code_actions()

	local results
	vim.lsp.buf_request_all(0, "textDocument/codeAction", function() return {} end, function(r) results = r end)

	restore_all()

	assert(results[1])
	assert(results[1].result[2])
	eq(#results[1].result, 2)
	eq(results[1].result[2].title, "Pick language")
	eq(results[1].result[2].command.command, "_ltex.pickLanguage")
end

T["ltex injection"]["always injects for ltex_plus regardless of languages"] = function()
	restore_all()
	local notes_lsp = require("notes.lsp")

	original_get_client_by_id = vim.lsp.get_client_by_id
	patch(vim.lsp, "get_client_by_id", function() return mock_client({}) end)

	install_test_request_mock({ { title = "server action" } })
	notes_lsp.setup_code_actions()

	local results
	vim.lsp.buf_request_all(0, "textDocument/codeAction", function() return {} end, function(r) results = r end)

	restore_all()

	assert(results[1])
	eq(#results[1].result, 2)
	eq(results[1].result[2].title, "Pick language")
end

T["ltex injection"]["does not inject for non-ltex clients"] = function()
	restore_all()
	local notes_lsp = require("notes.lsp")

	original_get_client_by_id = vim.lsp.get_client_by_id
	patch(vim.lsp, "get_client_by_id", function() return { name = "marksman", config = { settings = {} } } end)

	install_test_request_mock({ { title = "server action" } })
	notes_lsp.setup_code_actions()

	local results
	vim.lsp.buf_request_all(0, "textDocument/codeAction", function() return {} end, function(r) results = r end)

	restore_all()

	assert(results[1])
	eq(#results[1].result, 1)
	eq(results[1].result[1].title, "server action")
end

T["ltex injection"]["does not double-inject if Pick language already present"] = function()
	restore_all()
	local notes_lsp = require("notes.lsp")

	original_get_client_by_id = vim.lsp.get_client_by_id
	patch(vim.lsp, "get_client_by_id", function() return mock_client({ "en-US" }) end)

	install_test_request_mock({
		{ title = "existing", command = { command = "_ltex.pickLanguage" } },
	})
	notes_lsp.setup_code_actions()

	local results
	vim.lsp.buf_request_all(0, "textDocument/codeAction", function() return {} end, function(r) results = r end)

	restore_all()

	assert(results[1])
	eq(#results[1].result, 1)
end

return T
