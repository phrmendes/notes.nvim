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

T["native files"]["lists notes in subdirectories"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.create_note_files(child, temp_dir, {
		["top.md"] = "top",
		["journal/day.md"] = "day",
	})

	utils.mock.select(child)
	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").files(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items, 2)
	local names = vim.iter(items):map(function(i) return vim.fs.basename(i) end):totable()
	eq(vim.list_contains(names, "day.md"), true)
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

T["native grep"]["handles a pattern that starts with a dash"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua(string.format([[vim.fn.writefile({ "-foo bar" }, %q .. "/dash.md")]], temp_dir))

	utils.mock.input(child, "-foo")
	utils.mock.select(child)

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").grep(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items > 0, true)
end

T["native grep"]["handles regex special characters literally"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua(string.format([[vim.fn.writefile({ "(special chars)" }, %q .. "/special.md")]], temp_dir))

	utils.mock.input(child, "(special")
	utils.mock.select(child)

	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").grep(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items > 0, true)
end

T["native files"]["results are sorted alphabetically"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.create_note_files(child, temp_dir, {
		["c.md"] = "c",
		["a.md"] = "a",
		["b.md"] = "b",
	})

	utils.mock.select(child)
	utils.setup(child, temp_dir, "native")
	child.lua(string.format([[require("notes.picker").files(%q)]], temp_dir))

	local items = utils.mock.select_items(child)
	eq(#items, 3)
	eq(vim.fs.basename(items[1]), "a.md")
	eq(vim.fs.basename(items[2]), "b.md")
	eq(vim.fs.basename(items[3]), "c.md")
end

T["on_choice"] = new_set()

local capture_on_choice = function(input)
	utils.mock.cmd(child)
	if input then
		child.lua(string.format([[require("notes.picker.utils").on_choice(%q)]], input))
	else
		child.lua([[require("notes.picker.utils").on_choice(nil)]])
	end
	return child.lua([[
		return vim.iter(_G.mocked_cmds):map(function(c) return { c.cmd, c.args and c.args[1] } end):totable()
	]])
end

vim
	.iter({
		{ name = "returns early on nil", input = nil, expected = {} },
		{ name = "opens file at line when format is file:lnum:", input = "foo.md:42:matched text", expected = { { "edit", "foo.md" } } },
		{ name = "opens file when format is bare path", input = "just/a/path.md", expected = { { "edit", "just/a/path.md" } } },
		{ name = "path with non-numeric lnum falls back to bare path", input = "foo.md:notanumber:", expected = { { "edit", "foo.md:notanumber:" } } },
		{ name = "rejects line 0", input = "foo.md:0:text", expected = {} },
	})
	:each(function(case)
		T["on_choice"][case.name] = function()
			local cmds = capture_on_choice(case.input)
			eq(cmds, case.expected)
		end
	end)

T["mini backend"] = new_set()

T["mini backend"]["files calls mini_pick.start with items"] = function()
	local temp_dir = utils.create_temp_dir(child)
	utils.create_note_files(child, temp_dir, { ["a.md"] = "x" })

	utils.mock_mini_pick(child)
	utils.setup(child, temp_dir, "mini")
	utils.mock.select(child)

	child.lua(string.format([[require("notes.picker").files(%q)]], temp_dir))

	eq(child.lua_get("_G.captured_start_name"), "Notes")
	eq(type(child.lua_get("_G.captured_start_items")), "table")
	eq(child.lua_get("_G.captured_start_items")[1], "a.md")
end

T["mini backend"]["grep calls mini_pick.builtin.grep_live"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.mock_mini_pick(child)
	utils.setup(child, temp_dir, "mini")
	utils.mock.input(child, "hello")
	utils.mock.select(child)

	child.lua(string.format([[require("notes.picker").grep(%q)]], temp_dir))

	eq(child.lua_get("_G.captured_globs[1]"), "*.md")
	eq(child.lua_get("_G.captured_cwd"), temp_dir)
end

T["mini backend"]["grep turns NUL items into path:line: choices"] = function()
	local temp_dir = utils.create_temp_dir(child)
	child.lua(string.format([[vim.fn.writefile({ "hello" }, %q .. "/nested.md")]], temp_dir))

	utils.mock_mini_pick(child)
	utils.setup(child, temp_dir, "mini")
	utils.mock.cmd(child)

	child.lua(string.format([[require("notes.picker").grep(%q)]], temp_dir))

	local item = "nested.md\0" .. "1\0" .. "1\0" .. "hello"
	child.lua(string.format([[_G.captured_choose(%q)]], item))
	local cmd = child.lua_get("_G.mocked_cmds[1]")
	local expected = vim.fs.joinpath(temp_dir, "nested.md")
	eq(cmd.args[1], expected)
end

return T
