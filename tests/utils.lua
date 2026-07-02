local test = require("mini.test")
local eq = test.expect.equality

local utils = {}

---@type { date_prefix: string, id_suffix: string, md_end: string }
utils.patterns = {
	date_prefix = "^%d%d%d%d%d%d%d%d",
	id_suffix = "[A-Z][A-Z][A-Z][A-Z]",
	md_end = "%.md$",
}

utils.mock = {}

--- Create a temporary directory for tests
---@param child MiniTest.child
---@return string temp_dir
utils.create_temp_dir = function(child)
	local temp_id = child.lua_get("string.format('%d_%d', vim.uv.now(), math.random(1000, 9999))")
	local temp_dir = vim.fs.joinpath("/tmp", "notes.nvim", "test_" .. temp_id)
	child.lua(string.format("vim.fn.mkdir(%q, 'p')", temp_dir))
	return temp_dir
end

--- Assert that a file exists
---@param child MiniTest.child
---@param file_path string
utils.assert_file_exists = function(child, file_path) eq(child.lua_get(string.format("vim.uv.fs_stat(%q) ~= nil", file_path)), true) end

--- Read file content
---@param child MiniTest.child
---@param file_path string
---@return string[]
utils.read_file = function(child, file_path) return child.lua_get(string.format("vim.fn.readfile(%q)", file_path)) end

--- Create note files in a directory
---@param child MiniTest.child
---@param dir string
---@param files table<string, string> filename -> content
utils.create_note_files = function(child, dir, files)
	vim.iter(files):each(function(filename, content)
		local full_path = vim.fs.joinpath(dir, filename)
		local content_table = vim.iter(vim.split(content, "\n")):map(function(line) return string.format("%q", line) end):totable()

		child.lua(string.format("vim.fn.writefile({ %s }, %q)", table.concat(content_table, ", "), full_path))
	end)
end

--- Creates a child Neovim process with a test set pre-configured
--- with restart, cleanup, and stop hooks.
---@return table child The child Neovim process
---@return table T The test set with hooks configured
utils.new_child_set = function()
	local child = test.new_child_neovim()
	local T = test.new_set({
		hooks = {
			pre_case = function()
				child.restart({ "-u", "scripts/init.lua" })
				child.lua([[
					package.loaded.helpers = {
						get_dictionary_words = function() return {} end,
						add_word_to_dictionary = function(_, word) return { word } end,
					}
				]])
			end,
			post_case = function()
				local temp_dirs = child.lua_get("vim.fn.glob('/tmp/notes.nvim/test_*', 0, 1)")
				vim.iter(temp_dirs):each(function(dir) child.lua(string.format("vim.fn.delete(%q, 'rf')", dir)) end)
			end,
			post_once = function() child.stop() end,
		},
	})
	return child, T
end

--- Mock vim.ui.select to capture items without selecting
---@param child MiniTest.child
function utils.mock.select(child)
	child.lua([[
		_G.mocked_select = {}
		vim.ui.select = function(items, opts, callback)
			_G.mocked_select[1] = items
		end
	]])
end

--- Get items captured by mock.select
---@param child MiniTest.child
---@return table
function utils.mock.select_items(child) return child.lua_get("_G.mocked_select[1]") end

--- Mock vim.ui.input with a single canned response
---@param child MiniTest.child
---@param response string
function utils.mock.input(child, response) utils.mock.sequential_input(child, { response }) end

--- Mock vim.ui.input with sequential responses
---@param child MiniTest.child
---@param responses string[]
function utils.mock.sequential_input(child, responses)
	local quoted = vim.iter(responses):map(function(r) return string.format("%q", r) end):totable()

	child.lua(string.format(
		[[
		_G.mock_input_calls = 0
		_G.mock_input_responses = { %s }
		vim.ui.input = function(opts, callback)
			_G.mock_input_calls = _G.mock_input_calls + 1
			callback(_G.mock_input_responses[_G.mock_input_calls])
		end
	]],
		table.concat(quoted, ", ")
	))
end

--- Mock vim.notify to capture messages without displaying
---@param child MiniTest.child
function utils.mock.notify(child)
	child.lua([[
		_G.mocked_notify = {}
		vim.notify = function(msg, level)
			_G.mocked_notify[1] = msg
		end
	]])
end

--- Get the last message captured by mock.notify
---@param child MiniTest.child
---@return string|nil
function utils.mock.notify_message(child) return child.lua_get("_G.mocked_notify[1]") end

--- Mock vim.cmd to capture commands without executing
---@param child MiniTest.child
function utils.mock.cmd(child)
	child.lua([[
		_G.mocked_cmds = {}
		vim.cmd = function(cmd)
			table.insert(_G.mocked_cmds, cmd)
		end
	]])
end

--- Get commands captured by mock.cmd
---@param child MiniTest.child
---@return string[]
function utils.mock.cmds(child) return child.lua_get("_G.mocked_cmds") or {} end

--- Setup notes configuration in the child process
---@param child MiniTest.child
---@param path string
---@param picker string|nil
utils.setup = function(child, path, picker)
	local opts = string.format("{ path = %q", path)
	if picker then opts = opts .. string.format(', picker = "%s"', picker) end
	opts = opts .. " }"
	child.lua(string.format([[require("notes.config").setup(%s)]], opts))
end

--- Stub mini.pick in the child with a recording mock
---@param child MiniTest.child
function utils.mock_mini_pick(child)
	child.lua([[
		_G.captured_start_name = nil
		_G.captured_start_items = nil
		_G.captured_globs = nil
		_G.captured_cwd = nil
		package.loaded["mini.pick"] = {
			start = function(opts)
				_G.captured_start_name = opts.source.name
				_G.captured_start_items = opts.source.items
			end,
			builtin = {
				grep_live = function(opts, source_opts)
					_G.captured_globs = opts.globs
					_G.captured_cwd = source_opts.source.cwd
				end,
			},
			default_show = function() end,
		}
	]])
end

--- Glob journal entries in the child process
---@param child MiniTest.child
---@param temp_dir string
---@return table
utils.journal_glob = function(child, temp_dir)
	local pattern = vim.fs.joinpath(temp_dir, "journal")
	return child.lua_get(string.format("vim.fn.glob(%q .. '/*.md', 0, 1)", pattern))
end

return utils
