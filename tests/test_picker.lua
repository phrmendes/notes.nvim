local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality
local p = utils.patterns

local child, T = utils.new_child_set()

T["native files"] = new_set()

T["native files"]["lists .md files only"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.create_note_files(child, temp_dir, {
		["a.md"] = "content a",
		["b.md"] = "content b",
		["c.txt"] = "content c",
	})

	utils.mock.select(child)

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").files(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items, 2)
	eq(items[1]:match(p.md_end) ~= nil, true)
	eq(items[2]:match(p.md_end) ~= nil, true)
end

T["native files"]["empty dir shows empty list"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.mock.select(child)

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").files(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items, 0)
end

T["native grep"] = new_set()

T["native grep"]["finds matching file"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua(string.format([[vim.fn.writefile({ "hello world", "this is a test" }, %q .. "/test.md")]], temp_dir))

	utils.mock.input(child, "hello")
	utils.mock.select(child)

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").grep(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items > 0, true)
end

T["native grep"]["shows no matches for absent pattern"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua(string.format([[vim.fn.writefile({ "hello world" }, %q .. "/test.md")]], temp_dir))

	utils.mock.notify(child)
	utils.mock.input(child, "ZZXYZWQXYZXYZQ")

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").grep(%q)]], temp_dir))

	local notified = utils.mock.notify_message(child)
	eq(notified, "No matches found")
end

return T
