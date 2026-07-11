--- Picker-specific utilities

local coerce_to_string = require("notes.utils").coerce_to_string
local edit = require("notes.utils").edit

---@private
local utils = {}

--- Collect all .md files recursively from a directory
---@param dir string
---@return string[] Sorted absolute paths
utils.list_md_files = function(dir)
	local files = vim.fs.dir(dir, { depth = nil })
	local items = vim.iter(files):filter(function(file) return vim.endswith(file, ".md") end):map(function(file, _) return file end):totable()
	table.sort(items)
	return items
end

--- Run ripgrep and return parsed lines
---@param dir string
---@param glob string
---@param pattern string
---@return string[]|nil Lines in "file:lnum:text" format, or nil on error
utils.rg = function(dir, glob, pattern)
	if not pattern or pattern == "" then return nil end

	local obj = vim.system({ "rg", "-n", "--no-heading", "-F", "--color=never", "--glob", glob, pattern, dir }, { text = true }):wait()

	if obj.code == 1 then
		vim.notify("No matches found", vim.log.levels.INFO)
		return nil
	end

	if obj.code ~= 0 then
		vim.notify("Grep failed: exit code " .. obj.code, vim.log.levels.ERROR)
		return nil
	end

	local items = vim.iter(vim.split(obj.stdout or "", "\n", { trimempty = true })):filter(function(line) return line:find(":%d+:") ~= nil end):totable()

	if #items == 0 then
		vim.notify("No matches found", vim.log.levels.INFO)
		return nil
	end

	return items
end

--- Resolve the active picker or fall back to native
---@return PickerBackend
utils.get_picker = function() return require("notes.config").picker or require("notes.picker.native") end

--- Handle a chosen item — parses file:lnum: or bare path, then opens it.
--- Override via `require("notes.picker").on_choice` to change how notes are opened.
---@param choice string|nil
utils.on_choice = function(choice)
	if not choice then return end

	choice = coerce_to_string(choice)

	local parts = vim.split(choice, ":")
	local lnum = tonumber(parts[2] or "")

	if not lnum then
		edit(choice)
		return
	end

	edit(parts[1], lnum)
end

return utils
