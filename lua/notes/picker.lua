---
--- Picker module for notes.nvim
--- Supports native (vim.ui) and mini.pick backends
---

---@private
local M = {}

---@type PickerBackend
M.native = {}
---@type PickerBackend
M.mini = {}

--- Register a picker backend
---
--- Register a custom backend to use with `setup({ picker = name })`.
--- The backend must provide a `files(dir)` and `grep(dir)` function.
---
---@param name string Backend name (used as picker value in setup)
---@param backend table Backend with .files(dir) and .grep(dir) methods
---
--- Usage:
--- >lua
---   local picker = require("notes.picker")
---   picker.register("fzf", {
---     files = function(dir) ... end,
---     grep = function(dir) ... end,
---   })
---   require("notes").setup({ picker = "fzf" })
--- <
function M.register(name, backend) M[name] = backend end

--- Native backend: list .md files recursively using vim.fs.dir
---@param dir string
M.native.files = function(dir)
	local items = vim.iter(vim.fs.dir(dir, { depth = nil })):filter(function(name) return vim.endswith(name, ".md") end):map(function(name) return vim.fs.joinpath(dir, name) end):totable()

	vim.ui.select(items, { prompt = "Notes" }, function(choice)
		if choice then
			vim.cmd("edit " .. choice)
		end
	end)
end

--- Native backend: grep using vim.system + rg
---@param dir string
M.native.grep = function(dir)
	vim.ui.input({ prompt = "Grep pattern: " }, function(pattern)
		if not pattern or pattern == "" then
			return
		end

		local obj = vim.system({ "rg", "-n", "--no-heading", "--color=never", pattern, dir }, { text = true }):wait()

		if obj.code == 1 then
			vim.notify("No matches found", vim.log.levels.INFO)
			return
		end

		if obj.code ~= 0 then
			vim.notify("Grep failed: exit code " .. obj.code, vim.log.levels.ERROR)
			return
		end

		local items = vim.iter(vim.split(obj.stdout or "", "\n", { trimempty = true })):filter(function(line) return line:find(":%d+:") ~= nil end):totable()

		if #items == 0 then
			vim.notify("No matches found", vim.log.levels.INFO)
			return
		end

		vim.ui.select(items, { prompt = "Grep results" }, function(choice)
			if choice then
				local file, lnum = choice:match("^([^:]+):(%d+):")
				if file and lnum then
					vim.cmd("edit +" .. lnum .. " " .. file)
				end
			end
		end)
	end)
end

--- Mini backend: use mini.pick for files
---@param dir string
M.mini.files = function(dir)
	local pick = require("mini.pick")

	pick.builtin.cli({ command = { "fd", "-t", "f", "-e", "md" } }, {
		source = {
			name = "Notes",
			cwd = dir,
			show = function(buf_id, items, query) pick.default_show(buf_id, items, query, { show_icons = true }) end,
		},
	})
end

--- Mini backend: use mini.pick for grep
---@param dir string
M.mini.grep = function(dir)
	local mini_pick = require("mini.pick")

	mini_pick.builtin.grep_live({ globs = { "*.md" } }, {
		source = {
			name = "Search in notes",
			cwd = dir,
			show = function(buf_id, items, query) mini_pick.default_show(buf_id, items, query, { show_icons = true }) end,
		},
	})
end

-- Register built-in backends
M.register("native", M.native)
M.register("mini", M.mini)

--- Search for notes (list .md files)
---@param dir string | nil Directory to search (defaults to config path)
function M.files(dir)
	local c = require("notes.config")
	c.picker.files(dir or c.path)
end

--- Grep in notes
---@param dir string | nil Directory to search (defaults to config path)
function M.grep(dir)
	local c = require("notes.config")
	c.picker.grep(dir or c.path)
end

return M
