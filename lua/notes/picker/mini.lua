--- Mini.pick backend

local mini = {}

---@param dir string
---@param on_choice fun(choice: string|nil)
mini.files = function(items, dir, on_choice)
	local pick = require("mini.pick")

	pick.start({
		source = {
			items = items,
			name = "Notes",
			cwd = dir,
			choose = function(item) on_choice(item) end,
			show = function(buf_id, items_list, query) pick.default_show(buf_id, items_list, query, { show_icons = true }) end,
		},
	})
end

---@param dir string
---@param glob string
---@param on_choice fun(choice: string|nil)
mini.grep = function(dir, glob, on_choice)
	local pick = require("mini.pick")

	pick.builtin.grep_live({ globs = { glob } }, {
		source = {
			name = "Search in notes",
			cwd = dir,
			choose = function(item) on_choice(item) end,
			show = function(buf_id, items_list, query) pick.default_show(buf_id, items_list, query, { show_icons = true }) end,
		},
	})
end

return mini
