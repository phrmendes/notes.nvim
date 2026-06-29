---
--- Pure utility functions for notes.nvim
---

---@private
local utils = {}

--- Normalizes a word by converting it to lowercase, then replacing accented
--- their unaccented equivalents, and replacing spaces and non-word characters with hyphens.
---@param input string The input to normalize.
---@return string normalized_string The normalized input.
utils.normalize = function(input)
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
utils.create_tags = function(str, sep)
	local tags = vim.iter(string.gmatch(str, "([^" .. sep .. "]+)")):map(function(i) return "#" .. i:gsub("^%s*(.-)%s*$", "%1") end):totable()

	return table.concat(tags, ", ")
end

--- Generates a random string of characters or numbers.
---@param n number The length of the string.
---@param char? boolean If true, generates random uppercase letters; otherwise, generates random numbers.
---@return string random_str A string of random characters or numbers.
utils.generate_id = function(n, char)
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
utils.generate_file_id = function() return os.date("%Y%m%d") .. utils.generate_id(4, true) end

--- Parse a YYYY-MM-DD date string into a time value
---@param date_string string
---@return integer|nil time The date as os.time(), or nil if invalid
utils.parse_date = function(date_string)
	local year, month, day = date_string:match("^(%d%d%d%d)-(%d%d)-(%d%d)$")

	if not year then return nil end

	local y, m, d = tonumber(year), tonumber(month), tonumber(day)

	if not y or not m or not d then return nil end

	local time = os.time({ year = y, month = m, day = d })

	if not time then return nil end

	local t = os.date("*t", time)

	if t.year ~= y or t.month ~= m or t.day ~= d then return nil end

	return time
end

--- Write content to disk and open the file
---@param full_path string
---@param lines string[] Content lines
---@param label string Human-readable label for error messages
---@return string | nil full_path or nil on failure
utils.write_markdown_file = function(full_path, lines, label)
	local content = table.concat(lines, "\n") .. "\n"
	local fd = vim.uv.fs_open(full_path, "w", 420)

	if not fd then
		vim.notify("Failed to create " .. label .. ": could not open file", vim.log.levels.ERROR)
		return nil
	end

	local written = vim.uv.fs_write(fd, content)
	vim.uv.fs_close(fd)

	if written ~= #content then
		vim.notify("Failed to write " .. label .. ": incomplete write", vim.log.levels.ERROR)
		return nil
	end

	utils.edit(full_path)

	return full_path
end

--- Create directory and parents if they don't exist
---@param path string
---@return boolean created Whether a directory was created
utils.mkdirp = function(path)
	if vim.uv.fs_stat(path) then return false end

	local parent = vim.fs.dirname(path)

	if parent and parent ~= path then utils.mkdirp(parent) end

	vim.uv.fs_mkdir(path, 493)
	return true
end

--- Open a file in the current buffer
---
--- Handles two common cases that would otherwise prompt the user:
---
--- 1. A stale `.swp` file from a previous Neovim session (E13: "File
---    exists and is not a new version"). This happens when the file
---    was modified externally between sessions — the plugin writes
---    files via `fs_open` after the user has typed the title, which
---    makes any swap file from a prior crash definitively stale.
---
--- 2. The file is already loaded in another buffer (W13: "File has
---    changed since editing started"). In that case we switch to the
---    existing buffer and trigger a reload check.
---
---@param path string|nil
---@param lnum number|nil Line number to position the cursor at
utils.edit = function(path, lnum)
	if not path then return end

	-- If a buffer is already loaded for this path, switch to it and
	-- reload from disk to pick up our just-written content.
	local bufnr = vim.fn.bufnr(path)
	if bufnr ~= -1 and vim.api.nvim_buf_is_loaded(bufnr) then
		vim.api.nvim_set_current_buf(bufnr)
		pcall(vim.cmd, "checktime")
		if lnum then vim.api.nvim_win_set_cursor(0, { lnum, 0 }) end
		return
	end

	-- No loaded buffer. Use `silent! edit!` to suppress swap-file
	-- prompts and force-reload from disk. The file was either just
	-- written by us (definitely newer than any swap) or already
	-- existed (in which case `edit!` reloads it cleanly).
	local cmd = "silent! edit!"
	if lnum then cmd = cmd .. " +" .. lnum end
	cmd = cmd .. " " .. path
	pcall(vim.cmd, cmd)
end

return utils
