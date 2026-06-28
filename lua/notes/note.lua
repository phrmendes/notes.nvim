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

	local file_id = utils.generate_file_id()
	local filename = file_id .. "-" .. utils.normalize(title) .. ".md"
	local full_path = vim.fs.joinpath(path, filename)
	local lines = { "# " .. title, "" }

	if tags and tags ~= "" then
		local tags_line = "**Tags:** " .. utils.create_tags(tags, ",")
		table.insert(lines, tags_line)
		table.insert(lines, "")
	end

	return utils.write_markdown_file(full_path, lines, "note")
end

return note
