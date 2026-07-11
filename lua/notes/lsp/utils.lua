--- Shared utilities for the notes LSP module.
--- @module "notes.lsp.utils"

local ltex_path = vim.fs.joinpath(vim.fn.stdpath("data"), "ltex")

local utils = {}

--- Dispatch an LSP method call to the matching handler.
--- @param handlers table<string, function>
--- @param method string
--- @vararg any
--- @return boolean
function utils.dispatch(handlers, method, ...)
	local handler = handlers[method]
	if not handler then return false end
	local ok, err = pcall(handler, ...)
	if not ok then vim.notify("[notes.lsp] handler error (" .. method .. "): " .. tostring(err), vim.log.levels.ERROR) end
	return ok
end

--- Read all persisted ltex data (dictionary, disabledRules, hiddenFalsePositives).
--- @return table<string, table<string, string[]>>
function utils.read_ltex_data()
	local result = {}

	vim.iter({ "dictionary", "disabledRules", "hiddenFalsePositives" }):each(function(name)
		result[name] = {}
		local path = vim.fs.joinpath(ltex_path, name .. ".json")
		if not vim.uv.fs_stat(path) then return end
		local content = vim.fn.readfile(path)
		if not content[1] then return end
		local ok, data = pcall(vim.json.decode, content[1])
		if not ok or type(data) ~= "table" then return end
		result[name] = data
	end)

	return result
end

return utils
