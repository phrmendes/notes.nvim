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
	eq(type(config.root_dir), "function")
	eq(config.on_attach, nil)
end

T["lsp"]["marksman root_dir accepts a bufnr"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "marksman.lua")
	local config = loadfile(lsp_file)()

	-- Neovim 0.12+ passes a bufnr to root_dir; the function must
	-- resolve the buffer name and return a string root path.
	local temp_file = vim.fs.joinpath("/tmp", "notes.nvim", "root_dir_test.md")
	vim.fn.mkdir("/tmp/notes.nvim", "p")
	vim.fn.writefile({ "# test" }, temp_file)
	vim.cmd("edit " .. temp_file)
	local bufnr = vim.api.nvim_get_current_buf()

	local result = config.root_dir(bufnr)
	eq(type(result), "string")
	eq(vim.endswith(result, "notes.nvim"), true)
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
	eq(type(config.root_dir), "function")
	eq(type(config.on_attach), "function")
	eq(type(config.settings), "table")
	eq(type(config.settings.ltex), "table")
	eq(config.settings.ltex.language, "en-US")
	eq(type(config.settings.ltex.languages), "table")
	eq(#config.settings.ltex.languages, 3)
	eq(type(config.settings.ltex.dictionary), "table")
	eq(config.settings.ltex.spellCheck, true)
end

T["lsp"]["ltex_plus root_dir accepts a bufnr"] = function()
	local lsp_file = vim.fs.joinpath(vim.uv.cwd(), "lsp", "ltex_plus.lua")
	local config = loadfile(lsp_file)()

	-- Neovim 0.12+ passes a bufnr to root_dir; vim.fs.dirname
	-- requires a string, so the function must resolve via the
	-- buffer name.
	local temp_file = vim.fs.joinpath("/tmp", "notes.nvim", "ltex_root.md")
	vim.fn.writefile({ "# test" }, temp_file)
	vim.cmd("edit " .. temp_file)
	local bufnr = vim.api.nvim_get_current_buf()

	local result = config.root_dir(bufnr)
	eq(type(result), "string")
end

return T
