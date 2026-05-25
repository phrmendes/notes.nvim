---
--- Pure utility functions for notes.nvim
---

---@private
local M = {}

--- Normalizes a word by converting it to lowercase, replacing accented characters with
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
		["Á"] = "A",
		["À"] = "A",
		["Â"] = "A",
		["Ã"] = "A",
		["Ä"] = "A",
		["Å"] = "A",
		["É"] = "E",
		["È"] = "E",
		["Ê"] = "E",
		["Ë"] = "E",
		["Í"] = "I",
		["Ì"] = "I",
		["Î"] = "I",
		["Ï"] = "I",
		["Ó"] = "O",
		["Ò"] = "O",
		["Ô"] = "O",
		["Õ"] = "O",
		["Ö"] = "O",
		["Ø"] = "O",
		["Ú"] = "U",
		["Ù"] = "U",
		["Û"] = "U",
		["Ü"] = "U",
		["Ý"] = "Y",
		["Ÿ"] = "Y",
		["Ñ"] = "N",
		["Ç"] = "C",
	}

	vim.iter(replacements):each(function(accented, plain)
		normalized_input = normalized_input:gsub(accented, plain)
	end)

	normalized_input = normalized_input:gsub("[^%w%s]", ""):gsub("%s+", "-")

	return normalized_input
end

--- Creates a string of tags from a string.
---@param str string The string to split.
---@param sep string The separator to use for splitting the string.
---@return string tags A string with tags separated by commas and prefixed with #.
M.create_tags = function(str, sep)
	local tags = vim
		.iter(string.gmatch(str, "([^" .. sep .. "]+)"))
		:map(function(i)
			return "#" .. i:gsub("^%s*(.-)%s*$", "%1")
		end)
		:totable()

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
M.generate_file_id = function()
	return os.date("%Y%m%d") .. M.generate_id(4, true)
end

return M
