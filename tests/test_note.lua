local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality
local p = utils.patterns

local child, T = utils.new_child_set()

T["create"] = new_set()

T["create"]["creates file on disk with title and tags"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua(string.format([[require("notes.note").create("Hello", "tag1, tag2", %q)]], temp_dir))

	local files = child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", temp_dir))
	eq(#files, 1)

	utils.assert_file_exists(child, files[1])

	local content = utils.read_file(child, files[1])
	eq(content[1], "# Hello")
	eq(content[3], "**Tags:** #tag1, #tag2")
end

T["create"]["handles nil tags"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua(string.format([[require("notes.note").create("No Tags", nil, %q)]], temp_dir))

	local files = child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", temp_dir))
	eq(#files, 1)

	local content = utils.read_file(child, files[1])
	eq(content[1], "# No Tags")
	eq(#content, 2)
end

T["create"]["handles empty string tags"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua(string.format([[require("notes.note").create("Empty Tags", "", %q)]], temp_dir))

	local files = child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", temp_dir))
	eq(#files, 1)

	local content = utils.read_file(child, files[1])
	eq(content[1], "# Empty Tags")
	eq(#content, 2)
end

T["create"]["creates file with untitled heading"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua(string.format([[require("notes.note").create("", nil, %q)]], temp_dir))

	local files = child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", temp_dir))
	eq(#files, 1)

	utils.assert_file_exists(child, files[1])

	local content = utils.read_file(child, files[1])
	eq(content[1], "# untitled")

	local filename = vim.fs.basename(files[1])
	eq(filename:match(p.date_prefix .. p.id_suffix .. "%-untitled" .. p.md_end) ~= nil, true)
end

T["create"]["filename format is correct"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua(string.format([[require("notes.note").create("Test Title", nil, %q)]], temp_dir))

	local files = child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", temp_dir))
	eq(#files, 1)

	local filename = vim.fs.basename(files[1])
	eq(filename:match(p.date_prefix .. p.id_suffix .. "%-test%-title" .. p.md_end) ~= nil, true)
end

return T
