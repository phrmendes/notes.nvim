local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality

local child, T = utils.new_child_set()

T["journal"] = new_set()

local open_journal = function(date, tags, title_format)
	local date_arg = date and string.format("%q", date) or "nil"
	local tags_arg = tags and string.format("%q", tags) or "nil"

	child.lua(string.format(
		[[
			require("notes.config").setup({ path = %q%s })
			require("notes").journal(%s, %s)
		]],
		utils.last_temp_dir or "",
		title_format and string.format([[, journal = { title_format = %q }]], title_format) or "",
		date_arg,
		tags_arg
	))
end

vim
	.iter({
		{
			name = "creates today's entry with #journal tag",
			date = nil,
			tags = nil,
			expected_filename = os.date("%Y%m%d") .. ".md",
			expected_heading = "# " .. os.date("%Y-%m-%d"),
			expected_tags = "**Tags:** #journal",
		},
		{
			name = "opens specific date",
			date = "2026-01-15",
			tags = nil,
			expected_filename = "20260115.md",
			expected_heading = "# 2026-01-15",
			expected_tags = "**Tags:** #journal",
		},
		{
			name = "appends user tags to #journal",
			date = nil,
			tags = "work, daily",
			expected_filename = os.date("%Y%m%d") .. ".md",
			expected_heading = "# " .. os.date("%Y-%m-%d"),
			expected_tags = "**Tags:** #journal, #work, #daily",
		},
		{
			name = "respects custom title format",
			date = nil,
			tags = nil,
			title_format = "%Y/%m/%d",
			expected_filename = os.date("%Y%m%d") .. ".md",
			expected_heading = "# " .. os.date("%Y/%m/%d"),
			expected_tags = "**Tags:** #journal",
		},
	})
	:each(function(case)
		T["journal"][case.name] = function()
			local temp_dir = utils.create_temp_dir(child)
			utils.last_temp_dir = temp_dir

			utils.setup(child, temp_dir)
			open_journal(case.date, case.tags, case.title_format)

			local journal_dir = utils.journal_glob(child, temp_dir)
			eq(#journal_dir, 1)

			local filename = vim.fs.basename(journal_dir[1])
			eq(filename, case.expected_filename)

			local content = utils.read_file(child, journal_dir[1])
			eq(content[1], case.expected_heading)
			eq(content[3], case.expected_tags)
		end
	end)

T["journal"]["opens existing entry without creating duplicate"] = function()
	local temp_dir = utils.create_temp_dir(child)
	utils.last_temp_dir = temp_dir

	utils.setup(child, temp_dir)
	open_journal(nil, nil, nil)
	open_journal(nil, nil, nil)

	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)
end

T["journal"]["shows error for invalid date format"] = function()
	local temp_dir = utils.create_temp_dir(child)
	utils.last_temp_dir = temp_dir

	utils.setup(child, temp_dir)
	utils.mock.notify(child)
	open_journal("not-a-date", nil, nil)

	local notified = utils.mock.notify_message(child)
	eq(notified ~= nil, true)
end

T["journal"]["shows error when setup not called"] = function()
	utils.mock.notify(child)
	child.lua([[require("notes").journal()]])

	local notified = utils.mock.notify_message(child)
	eq(notified ~= nil, true)
end

T["journal"]["supports brazilian portuguese locale"] = function()
	local temp_dir = utils.create_temp_dir(child)
	utils.last_temp_dir = temp_dir

	child.lua([[
		local ok = pcall(os.setlocale, "pt_BR.UTF-8")
		_G.locale_pt = ok
	]])

	if not child.lua_get("_G.locale_pt") then return end

	open_journal("2026-04-13", nil, "%d de %B de %Y")

	local journal_dir = utils.journal_glob(child, temp_dir)
	eq(#journal_dir, 1)

	local content = utils.read_file(child, journal_dir[1])
	eq(content[1], "# 13 de abril de 2026")
end

return T
