--- Mini.pick backend

local mini = {}

---@param dir string
---@param on_choice fun(choice: string|nil)
mini.files = function(items, dir, on_choice)
	local ok, pick = pcall(require, "mini.pick")

	if not ok then
		vim.notify("mini.pick not available", vim.log.levels.ERROR)
		return
	end

	pick.start({
		source = {
			items = items,
			name = "Notes",
			cwd = dir,
			choose = on_choice,
			show = function(buf_id, items_list, query) pick.default_show(buf_id, items_list, query, { show_icons = true }) end,
		},
	})
end

---@param dir string
---@param glob string
---@param on_choice fun(choice: string|nil)
mini.grep = function(dir, glob, on_choice)
	local ok, pick = pcall(require, "mini.pick")

	if not ok then
		vim.notify("mini.pick not available", vim.log.levels.ERROR)
		return
	end

	pick.builtin.grep_live({ globs = { glob } }, {
		source = {
			name = "Search in notes",
			cwd = dir,
			choose = on_choice,
			show = function(buf_id, items_list, query) pick.default_show(buf_id, items_list, query, { show_icons = true }) end,
		},
	})
end

return mini
