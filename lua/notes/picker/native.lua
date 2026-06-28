--- Native picker backend — uses vim.ui.select / vim.ui.input

local rg = require("notes.picker.utils").rg

local native = {}

---@param _ string|nil
---@param on_choice fun(choice: string|nil)
native.files = function(items, _, on_choice) vim.ui.select(items, { prompt = "Notes" }, on_choice) end

---@param dir string
---@param glob string
---@param on_choice fun(choice: string|nil)
native.grep = function(dir, glob, on_choice)
	vim.ui.input({ prompt = "Grep pattern: " }, function(pattern)
		local items = rg(dir, glob, pattern)

		if items then
			vim.ui.select(items, { prompt = "Grep results" }, on_choice)
		end
	end)
end

return native
