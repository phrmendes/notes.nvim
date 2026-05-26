---
--- Journal module for notes.nvim
---

local config = require("notes.config")
local utils = require("notes.utils")

---@private
local M = {}

--- Resolve a date string to a time value
---@param date string | nil
---@return integer | nil time
---@return string | nil error_message
local function resolve_time(date)
	if not date then
		return os.time()
	end

	local time = utils.parse_date(date)

	if not time then
		return nil, "Invalid date: " .. date .. " (expected YYYY-MM-DD)"
	end

	return time
end

--- Build the title and full path for a journal entry
---@param time integer
---@param journal_path string
---@return string title
---@return string full_path
local function build_path(time, journal_path)
	local title = tostring(os.date(config.journal.title_format, time))
	local filename = tostring(os.date(config.journal.filename_format, time)):gsub("/", "-") .. ".md"
	local path = vim.fs.joinpath(journal_path, filename)
	return title, path
end

--- Write journal entry content to disk
---@param path string
---@param title string
---@param tags string | nil
---@return string | nil full_path or nil on failure
local function write_entry(path, title, tags)
	local lines = { "# " .. title, "" }
	local all_tags = "#journal"

	if tags and tags ~= "" then
		all_tags = all_tags .. ", " .. utils.create_tags(tags, ",")
	end

	table.insert(lines, "**Tags:** " .. all_tags)
	table.insert(lines, "")

	return utils.write_markdown_file(path, lines, "journal entry")
end

--- Open or create a journal entry for the given date
---@param date_string string | nil Date in YYYY-MM-DD format (defaults to today)
---@param tags string | nil Comma-separated user tags
---@return string | nil The path of the journal entry, or nil if creation failed
function M.open(date_string, tags)
	local journal_path = config.journal.path

	if not journal_path then
		vim.notify("Journal not configured: run setup() first", vim.log.levels.ERROR)
		return nil
	end

	local time, err = resolve_time(date_string)

	if not time then
		vim.notify(err or "Invalid journal date", vim.log.levels.ERROR)
		return nil
	end

	local title, full_path = build_path(time, journal_path)

	if vim.uv.fs_stat(full_path) then
		vim.cmd("edit " .. full_path)
		return full_path
	end

	return write_entry(full_path, title, tags)
end

return M
