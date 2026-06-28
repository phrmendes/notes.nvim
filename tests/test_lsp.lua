local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

T["lsp"] = new_set()

T["lsp"]["does nothing when lsp.marksman is false"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.captured_lsp_enable = nil
		vim.lsp.enable = function(name) _G.captured_lsp_enable = name end
	]])

	child.lua([[require("notes.config").setup({ path = require("notes.config").path, lsp = { marksman = false } })]])

	eq(child.lua_get("_G.captured_lsp_enable == nil"), true)
end

T["lsp"]["auto-enables marksman by default"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua([[
		_G.captured_lsp_enable = nil
		vim.lsp.enable = function(name) _G.captured_lsp_enable = name end
	]])

	child.lua(string.format([[require("notes.config").setup({ path = %q })]], temp_dir))

	eq(child.lua_get("_G.captured_lsp_enable"), "marksman")
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
	eq(type(config.on_attach), "function")
end

return T
