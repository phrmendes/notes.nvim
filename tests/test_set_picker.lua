local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

T["set_picker"] = new_set()

T["set_picker"]["default is auto-detected"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").set_picker("native")]])

	eq(child.lua_get([[type(require('notes.config').picker) == "table" and type(require('notes.config').picker.files) == "function"]]), true)
end

T["set_picker"]["swaps to mini"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir, "native")
	child.lua([[require("notes").set_picker("mini")]])

	eq(child.lua_get([[type(require('notes.config').picker) == "table" and type(require('notes.config').picker.files) == "function"]]), true)
end

T["set_picker"]["unknown name sets picker to nil"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir, "native")
	child.lua([[require("notes").set_picker("nonexistent")]])

	eq(child.lua_get("require('notes.config').picker == nil"), true)
end

T["set_picker"]["swap affects subsequent picker.files call"] = function()
	local temp_dir = utils.create_temp_dir(child)
	utils.create_note_files(child, temp_dir, { ["a.md"] = "x", ["b.md"] = "y" })

	utils.setup(child, temp_dir, "native")
	utils.mock.select(child)

	child.lua(string.format([[require("notes.picker").files(%q)]], temp_dir))
	local first_items = utils.mock.select_items(child)
	eq(#first_items, 2)

	child.lua([[require("notes").set_picker("nonexistent")]])
	utils.mock.select(child)
	child.lua(string.format([[require("notes.picker").files(%q)]], temp_dir))
	local second_items = utils.mock.select_items(child)
	eq(#second_items, 2)
end

return T
