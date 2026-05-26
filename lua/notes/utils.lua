---
--- Pure utility functions for notes.nvim
---

---@private
local M = {}

--- Normalizes a word by converting it to lowercase, then replacing accented
--- their unaccented equivalents, and replacing spaces and non-word characters with hyphens.
---@param input string The input to normalize.
---@return string normalized_string The normalized input.
M.normalize = function(input)
	local normalized_input = input:lower()

	local replacements = {
		["á"] = "a",
		["à"] = "a",
		["â"] = "a",
		["ã"] = "a",
		["ä"] = "a",
		["å"] = "a",
		["é"] = "e",
		["è"] = "e",
		["ê"] = "e",
		["ë"] = "e",
		["í"] = "i",
		["ì"] = "i",
		["î"] = "i",
		["ï"] = "i",
		["ó"] = "o",
		["ò"] = "o",
		["ô"] = "o",
		["õ"] = "o",
		["ö"] = "o",
		["ø"] = "o",
		["ú"] = "u",
		["ù"] = "u",
		["û"] = "u",
		["ü"] = "u",
		["ý"] = "y",
		["ÿ"] = "y",
		["ñ"] = "n",
		["ç"] = "c",
		["ß"] = "ss",
	}

	vim.iter(replacements):each(function(accented, plain) normalized_input = normalized_input:gsub(accented, plain) end)

	normalized_input = normalized_input:gsub("[^%w%s]", ""):gsub("%s+", "-")

	return normalized_input
end

--- Creates a string of tags from a string.
---@param str string The string to split.
---@param sep string The separator to use for splitting the string.
---@return string tags A string with tags separated by commas and prefixed with #.
M.create_tags = function(str, sep)
	local tags = vim.iter(string.gmatch(str, "([^" .. sep .. "]+)")):map(function(i) return "#" .. i:gsub("^%s*(.-)%s*$", "%1") end):totable()

	return table.concat(tags, ", ")
end

--- Generates a random string of characters or numbers.
---@param n number The length of the string.
---@param char? boolean If true, generates random uppercase letters; otherwise, generates random numbers.
---@return string random_str A string of random characters or numbers.
M.generate_id = function(n, char)
	local base = char and 65 or 48
	local offset = char and 25 or 9
	local chars = {}

	for i = 1, n do
		chars[i] = string.char(math.random(base, base + offset))
	end

	return table.concat(chars)
end

--- Generates a file ID with date prefix.
---@return string file_id A string in format YYYYMMDDXXXX (date + 4 random uppercase letters)
M.generate_file_id = function() return os.date("%Y%m%d") .. M.generate_id(4, true) end

--- Parse a YYYY-MM-DD date string into a time value
---@param date_string string
---@return integer|nil time The date as os.time(), or nil if invalid
M.parse_date = function(date_string)
	local year, month, day = date_string:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")
	if not year then
		return nil
	end
	return os.time({
		year = tonumber(year) or 0,
		month = tonumber(month) or 0,
		day = tonumber(day) or 0,
	})
end

--- Write content to disk and open the file
---@param full_path string
---@param lines string[] Content lines
---@param label string Human-readable label for error messages
---@return string | nil full_path or nil on failure
M.write_markdown_file = function(full_path, lines, label)
	local content = table.concat(lines, "\n") .. "\n"
	local fd = vim.uv.fs_open(full_path, "w", 420)

	if not fd then
		vim.notify("Failed to create " .. label .. ": could not open file", vim.log.levels.ERROR)
		return nil
	end

	vim.uv.fs_write(fd, content)
	vim.uv.fs_close(fd)

	vim.cmd("edit " .. full_path)

	return full_path
end

--- Create directory and parents if they don't exist
---@param path string
---@return boolean created Whether a directory was created
M.mkdirp = function(path)
	if vim.uv.fs_stat(path) then
		return false
	end

	local parent = vim.fs.dirname(path)

	if parent and parent ~= path then
		M.mkdirp(parent)
	end

	vim.uv.fs_mkdir(path, 493)
	return true
end

return M
