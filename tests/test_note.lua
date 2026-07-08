local test = require("mini.test")
local utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality
local p = utils.patterns

local child, T = utils.new_child_set()

T["create"] = new_set()

local create_note = function(title, tags, path) child.lua(string.format([[require("notes.note").create(%q, %s, %q)]], title, tags and string.format("%q", tags) or "nil", path)) end

local get_files = function(dir) return utils.glob_md(child, dir) end

vim
	.iter({
		{
			name = "creates file with title and tags",
			title = "Hello",
			tags = "tag1, tag2",
			check = function(_, content)
				eq(content[1], "# Hello")
				eq(content[3], "**Tags:** #tag1, #tag2")
			end,
		},
		{
			name = "handles nil tags",
			title = "No Tags",
			tags = nil,
			check = function(_, content)
				eq(content[1], "# No Tags")
				eq(#content, 2)
			end,
		},
		{
			name = "handles empty string tags",
			title = "Empty Tags",
			tags = "",
			check = function(_, content)
				eq(content[1], "# Empty Tags")
				eq(#content, 2)
			end,
		},
		{
			name = "empty title becomes untitled",
			title = "",
			tags = nil,
			check = function(files, content)
				eq(content[1], "# untitled")
				local filename = vim.fs.basename(files[1])
				eq(filename:match(p.date_prefix .. p.id_suffix .. "%-untitled" .. p.md_end) ~= nil, true)
			end,
		},
		{
			name = "filename format is correct",
			title = "Test Title",
			tags = nil,
			check = function(files)
				local filename = vim.fs.basename(files[1])
				eq(filename:match(p.date_prefix .. p.id_suffix .. "%-test%-title" .. p.md_end) ~= nil, true)
			end,
		},
	})
	:each(function(case)
		T["create"][case.name] = function()
			local temp_dir = utils.temp_dir()
			utils.setup(child, temp_dir)
			create_note(case.title, case.tags, temp_dir)

			local files = get_files(temp_dir)
			eq(#files, 1)
			utils.assert_file_exists(child, files[1])

			local content = utils.read_file(child, files[1])
			case.check(files, content, temp_dir)
		end
	end)

T["create"]["creates parent directories for custom path"] = function()
	local temp_dir = utils.temp_dir()
	local sub_dir = vim.fs.joinpath(temp_dir, "sub", "deep")

	utils.setup(child, temp_dir)
	create_note("Deep Note", nil, sub_dir)

	local files = get_files(sub_dir)
	eq(#files, 1)
	utils.assert_file_exists(child, files[1])

	local content = utils.read_file(child, files[1])
	eq(content[1], "# Deep Note")
end

return T
