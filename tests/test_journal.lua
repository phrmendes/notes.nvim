local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

T["journal"] = new_set()

T["journal"]["creates today's entry with #journal tag"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal()]])

	local today = os.date("%Y%m%d")
	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)

	local filename = vim.fs.basename(journal_dir[1])
	eq(filename, today .. ".md")

	local content = utils.read_file(child, journal_dir[1])
	eq(content[1], "# " .. os.date("%Y-%m-%d"))
	eq(content[3], "**Tags:** #journal")
end

T["journal"]["opens existing entry without creating duplicate"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal()]])
	child.lua([[require("notes").journal()]])

	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)
end

T["journal"]["opens specific date"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal("2026-01-15")]])

	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)

	local filename = vim.fs.basename(journal_dir[1])
	eq(filename, "20260115.md")

	local content = utils.read_file(child, journal_dir[1])
	eq(content[1], "# 2026-01-15")
	eq(content[3], "**Tags:** #journal")
end

T["journal"]["appends user tags to #journal"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[require("notes").journal(nil, "work, daily")]])

	local journal_dir = utils.journal_glob(child, temp_dir)
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

	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)

	local content = utils.read_file(child, journal_dir[1])
	local today = os.date("%Y/%m/%d")
	eq(content[1], "# " .. today)
end

T["journal"]["filename is always YYYYMMDD"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua(string.format(
		[[
			require("notes.config").setup({ path = %q, journal = { title_format = "%%Y/%%m/%%d" } })
			require("notes").journal()
		]],
		temp_dir
	))

	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)

	local filename = vim.fs.basename(journal_dir[1])
	local today = os.date("%Y%m%d")
	eq(filename, today .. ".md")
end

T["journal"]["supports brazilian portuguese locale"] = function()
	local temp_dir = utils.create_temp_dir(child)

	child.lua([[
		local ok = pcall(os.setlocale, "pt_BR.UTF-8")
		_G.locale_pt = ok
	]])

	if not child.lua_get("_G.locale_pt") then
		return
	end

	child.lua(string.format(
		[[
			require("notes.config").setup({ path = %q, journal = { title_format = "%%d de %%B de %%Y" } })
			require("notes").journal("2026-04-13")
		]],
		temp_dir
	))

	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)

	local content = utils.read_file(child, journal_dir[1])
	eq(content[1], "# 13 de abril de 2026")
end

T["journal"]["shows error for invalid date format"] = function()
	local temp_dir = utils.create_temp_dir(child)

	utils.setup(child, temp_dir)
	child.lua([[
		_G.notified = {}
		vim.notify = function(msg, level)
			_G.notified[1] = msg
		end
		require("notes").journal("not-a-date")
	]])

	local notified = child.lua_get("_G.notified[1]")
	eq(notified ~= nil, true)
end

T["journal"]["shows error when setup not called"] = function()
	child.lua([[
		_G.notified = {}
		vim.notify = function(msg, level)
			_G.notified[1] = msg
		end
		require("notes").journal()
	]])

	local notified = child.lua_get("_G.notified[1]")
	eq(notified ~= nil, true)
end

return T
