---
--- A simple note taking plugin for neovim.
---
--- MIT License Copyright (c) 2024 Pedro Mendes
---
--- # Setup ~
---
--- local add = require("mini.deps").add
---
--- >lua
--- add({
--- 	source = "phrmendes/notes.nvim",
--- 	depends = { "echasnovski/mini.nvim" },
--- 	-- depends = { "echasnovski/mini.pick" },
--- })
--- <
---
--- # Configuration ~
---
--- You can configure the plugin by calling the `setup` function. The default path
--- for notes is `~/Documents/notes`.
---
--- >lua
--- local later = require("mini.deps")
---
--- later(function()
---   require("notes").setup({ path = "path/to/your/notes" })
--- end)
--- <
--- ==============================================================================
--- @module 'notes'
local notes = {}
local config = {}

--- @class Setup
--- @field path string: Path to the notes directory

--- @class FileContent
--- @field path string: The path to the file.
--- @field content string[]: The content to add to the file.

--- Normalizes a word by converting it to lowercase, replacing accented characters with their unaccented equivalents,
--- and replacing spaces and non-word characters with underscores.
--- @param word string: The word to normalize.
--- @return string: The normalized word.
local normalize_string = function(word)
	local normalized_word = word:lower():gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
		return c:gsub("[áàâ]", "a")
			:gsub("[éèê]", "e")
			:gsub("[íìî]", "i")
			:gsub("[óòô]", "o")
			:gsub("[úùû]", "u")
			:gsub("[ç]", "c")
	end)

	local string, _ = normalized_word:gsub("[%s%W]", "_")

	return string
end

--- Creates an array of tags from a string.
--- @param str string: The string to split.
--- @param sep string: The separator to use for splitting the string.
--- @return string: A string with tags separated by commas.
local function create_tags(str, sep)
	local tags = {}

	for i in string.gmatch(str, "([^" .. sep .. "]+)") do
		-- remove leading and trailing whitespaces
		i = i:gsub("^%s*(.-)%s*$", "%1")

		table.insert(tags, "#" .. i)
	end

	return table.concat(tags, ", ")
end

--- Generates an array of random characters or numbers.
--- @param n number: The length of the array.
--- @param char? boolean: If true, generates random uppercase letters; otherwise, generates random numbers.
--- @return (integer | string)[]: An array of random characters or numbers.
local generate_random_array = function(n, char)
	local array = {}
	local upper, lower

	if char then
		upper, lower = 65, 90 -- ASCII values for 'A' to 'Z'
	else
		upper, lower = 0, 9
	end

	while #array < n do
		if char then
			table.insert(array, string.char(math.random(upper, lower)))
		else
			table.insert(array, math.random(upper, lower))
		end
	end

	return array
end

--- Adds content to a file.
--- @param opts FileContent: Options for adding content to a file.
local function add_content_to_file(opts)
	vim.cmd("vnew " .. opts.path)

	local buf = vim.api.nvim_get_current_buf()

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, opts.content)
end

--- Search for notes (in markdown files)
--- @param path string | nil: Path to search in
--- @return nil
notes.search = function(path)
	path = path or config.path

	require("mini.pick").builtin.cli({
		command = { "fd", "-t", "f", "-e", "md" },
	}, {
		source = {
			name = "Notes",
			cwd = path,
			show = function(buf_id, items, query)
				require("mini.pick").default_show(buf_id, items, query, { show_icons = true })
			end,
		},
	})
end

--- Live grep in notes (in markdown files)
--- @param path string | nil: Path to grep in
--- @return nil
notes.grep_live = function(path)
	path = path or config.path

	require("mini.pick").builtin.grep_live({
		globs = { "*.md" },
	}, {
		source = {
			name = "Search in notes",
			cwd = path,
			show = function(buf_id, items, query)
				require("mini.pick").default_show(buf_id, items, query, { show_icons = true })
			end,
		},
	})
end

--- Create a new note
--- @param path string | nil: Path to create the note in
--- @return nil
notes.new = function(path)
	path = path or config.path

	vim.ui.input({ prompt = "Title: " }, function(title)
		if title == "" or title == nil then
			vim.notify("Note not created: title can't be empty", vim.log.levels.ERROR)
			return
		end

		local id = table.concat(generate_random_array(4, true))
		local date = os.date("%Y%m%d")

		local opts = {
			content = { "# " .. title, "" },
			path = path .. "/" .. date .. id .. "-" .. normalize_string(title) .. ".md",
		}

		vim.ui.input({ prompt = "Tags (separated by comma): " }, function(tags)
			if tags ~= "" and tags ~= nil then
				opts.content = vim.list_extend(opts.content, { "**Tags:** " .. create_tags(tags, ","), "" })
			end

			add_content_to_file(opts)
		end)
	end)
end

--- Setup function
--- @param opts Setup
notes.setup = function(opts)
	opts = opts or {}
	config.path = opts.path or vim.env.HOME .. "/Documents/notes"
end

return notes
