local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

T["journal"] = new_set()

local function journal_glob(temp_dir)
	local pattern = vim.fs.joinpath(temp_dir, "journal")
	return child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", pattern))
end

T["journal"]["creates today's entry with #journal tag"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal()]])

	local today = os.date("%Y-%m-%d")
	local journal_dir = journal_glob(temp_dir)
	eq(#journal_dir, 1)

	local filename = vim.fs.basename(journal_dir[1])
	eq(filename, today .. ".md")

	local content = utils.read_file(child, journal_dir[1])
	eq(content[1], "# " .. today)
	eq(content[3], "**Tags:** #journal")
end

T["journal"]["opens existing entry without creating duplicate"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal()]])
	child.lua([[require("notes").journal()]])

	local journal_dir = journal_glob(temp_dir)
	eq(#journal_dir, 1)
end

T["journal"]["opens specific date"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal("2026-01-15")]])

	local journal_dir = journal_glob(temp_dir)
	eq(#journal_dir, 1)

	local filename = vim.fs.basename(journal_dir[1])
	eq(filename, "2026-01-15.md")

	local content = utils.read_file(child, journal_dir[1])
	eq(content[1], "# 2026-01-15")
	eq(content[3], "**Tags:** #journal")
end

T["journal"]["appends user tags to #journal"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal(nil, "work, daily")]])

	local journal_dir = journal_glob(temp_dir)
	eq(#journal_dir, 1)

	local content = utils.read_file(child, journal_dir[1])
	eq(content[3], "**Tags:** #journal, #work, #daily")
end

T["journal"]["respects custom title format"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua(string.format(
		[[
			require("notes.config").setup({ path = %q, journal = { title_format = "%%Y/%%m/%%d" } })
			require("notes").journal()
		]],
		temp_dir
	))

	local journal_dir = journal_glob(temp_dir)
	eq(#journal_dir, 1)

	local content = utils.read_file(child, journal_dir[1])
	local today = os.date("%Y/%m/%d")
	eq(content[1], "# " .. today)
end

T["journal"]["respects custom filename format"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua(string.format(
		[[
			require("notes.config").setup({ path = %q, journal = { filename_format = "%%Y%%m%%d" } })
			require("notes").journal()
		]],
		temp_dir
	))

	local journal_dir = journal_glob(temp_dir)
	eq(#journal_dir, 1)

	local filename = vim.fs.basename(journal_dir[1])
	local today = os.date("%Y%m%d")
	eq(filename, today .. ".md")
end

return T
