--- Persistent data reader for ltex dictionary, disabled rules, and hidden false positives.
---
--- Reads JSON files at `~/.local/share/nvim/ltex/` for three categories:
--- `dictionary`, `disabledRules`, `hiddenFalsePositives`. Both `lua/notes/lsp.lua`
--- and `lsp/ltex_plus.lua` use this module instead of defining their own readers.

local ltex_path = vim.fs.joinpath(vim.fn.stdpath("data"), "ltex")

local ltex = {}

--- Category names for persisted ltex data.
ltex.categories = { "dictionary", "disabledRules", "hiddenFalsePositives" }

--- Read a category's persisted data from its JSON file.
---@param name string Category name (e.g. "dictionary")
---@return table<string, string[]> Map of language to items
local function read_category(name)
	local path = vim.fs.joinpath(ltex_path, name .. ".json")
	if not vim.uv.fs_stat(path) then return {} end

	local content = vim.fn.readfile(path)
	if not content[1] then return {} end

	local ok, data = pcall(vim.json.decode, content[1])
	if not ok or type(data) ~= "table" then return {} end

	return data
end

--- Read all three persisted categories from disk.
---@return table<string, table<string, string[]>> Map of category → language → items
function ltex.read_all()
	local result = {}
	for _, name in ipairs(ltex.categories) do
		result[name] = read_category(name)
	end
	return result
end

return ltex
