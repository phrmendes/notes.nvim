---
--- Note creation module for notes.nvim
---

local config = require("notes.config")
local utils = require("notes.utils")

---@private
local note = {}

--- Create a new note
---@param title string The title of the note
---@param tags string | nil Comma-separated tags (optional)
---@param path string | nil Custom path for the note (optional)
---@return string | nil The path of the created note, or nil if creation failed
function note.create(title, tags, path)
	title = (not title or title == "") and "untitled" or title

	path = path or config.path
	utils.mkdirp(path)

	local slug = utils.normalize(title)
	if slug == "" then slug = "untitled" end

	local lines = { "# " .. title, "" }

	if tags and tags ~= "" then
		local tags_line = "**Tags:** " .. utils.create_tags(tags, ",")
		table.insert(lines, tags_line)
		table.insert(lines, "")
	end

	-- `wx` never truncates an existing note. Retry with a new ID on collision.
	for _ = 1, 5 do
		local filename = utils.generate_file_id() .. "-" .. slug .. ".md"
		local full_path = vim.fs.joinpath(path, filename)
		local written = utils.write_markdown_file(full_path, lines, "note", "wx")
		if written then return written end
		if not vim.uv.fs_stat(full_path) then
			vim.notify("Failed to create note: could not open file", vim.log.levels.ERROR)
			return nil
		end
	end

	vim.notify("Failed to create note: no unused file name", vim.log.levels.ERROR)
	return nil
end

return note
