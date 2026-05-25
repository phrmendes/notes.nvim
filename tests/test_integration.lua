local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

T["integration"] = new_set()

T["integration"]["full create and search flow"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir, "native")

	utils.mock.sequential_input(child, { "Integration Test", "test, integration" })

	child.lua([[require("notes").new()]])

	local files = child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", temp_dir))
	eq(#files, 1)

	local content = utils.read_file(child, files[1])
	eq(content[1], "# Integration Test")
	eq(content[3], "**Tags:** #test, #integration")
end

T["integration"]["search lists created note"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[vim.fn.writefile({ "# Existing Note", "" }, %q .. "/existing.md")]], temp_dir))

	utils.mock.select(child)

	child.lua(string.format([[require("notes").search(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items, 1)
	eq(items[1]:match("existing.md") ~= nil, true)
end

T["integration"]["grep finds note content"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[vim.fn.writefile({ "unique search term", "" }, %q .. "/searchable.md")]], temp_dir))

	utils.mock.input(child, "unique search term")
	utils.mock.select(child)

	child.lua(string.format([[require("notes").grep(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items > 0, true)
end

return T
