local test = require("mini.test")
local new_set, eq = test.new_set, test.expect.equality

local T = new_set()

local original_buf_request_all
local original_get_client_by_id

local function restore_buf_request_all()
	require("notes.lsp").reset_code_actions()
	if original_buf_request_all then
		vim.lsp.buf_request_all = original_buf_request_all
		original_buf_request_all = nil
	end
	if original_get_client_by_id then
		vim.lsp.get_client_by_id = original_get_client_by_id
		original_get_client_by_id = nil
	end
end

T["notes lsp"] = new_set()

T["notes lsp"]["setup_code_actions patches vim.lsp.buf_request_all"] = function()
	restore_buf_request_all()
	local notes_lsp = require("notes.lsp")

	local original = vim.lsp.buf_request_all
	notes_lsp.setup_code_actions()

	eq(vim.lsp.buf_request_all ~= original, true)

	restore_buf_request_all()
end

T["notes lsp"]["setup_code_actions is idempotent"] = function()
	restore_buf_request_all()
	local notes_lsp = require("notes.lsp")

	notes_lsp.setup_code_actions()
	local patched = vim.lsp.buf_request_all
	notes_lsp.setup_code_actions()

	eq(vim.lsp.buf_request_all, patched)

	restore_buf_request_all()
end

T["notes lsp"]["injects Pick language for ltex_plus client"] = function()
	restore_buf_request_all()
	local notes_lsp = require("notes.lsp")

	original_get_client_by_id = vim.lsp.get_client_by_id
	vim.lsp.get_client_by_id = function() return { name = "ltex_plus" } end

	original_buf_request_all = vim.lsp.buf_request_all
	vim.lsp.buf_request_all = function(_, method, _, callback)
		if method == "textDocument/codeAction" then callback({
			[1] = {
				result = { { title = "server action" } },
				context = { client_id = 1 },
			},
		}) end
	end

	notes_lsp.setup_code_actions()

	local results = nil
	vim.lsp.buf_request_all(0, "textDocument/codeAction", function() return {} end, function(r) results = r end)

	restore_buf_request_all()

	eq(#results[1].result, 2)
	eq(results[1].result[2].title:find("Pick language") ~= nil, true)
	eq(results[1].result[2].command.command, "_ltex.pickLanguage")
end

T["notes lsp"]["does not inject for non-ltex clients"] = function()
	restore_buf_request_all()
	local notes_lsp = require("notes.lsp")

	original_get_client_by_id = vim.lsp.get_client_by_id
	vim.lsp.get_client_by_id = function() return { name = "marksman" } end

	notes_lsp.setup_code_actions()

	vim.lsp.buf_request_all = function(_, method, _, callback)
		if method == "textDocument/codeAction" then callback({
			[1] = {
				result = { { title = "server action" } },
				context = { client_id = 1 },
			},
		}) end
	end

	local results
	vim.lsp.buf_request_all(0, "textDocument/codeAction", function() return {} end, function(r) results = r end)

	restore_buf_request_all()

	eq(#results[1].result, 1)
	eq(results[1].result[1].title, "server action")
end

T["notes lsp"]["does not double-inject if Pick language already present"] = function()
	restore_buf_request_all()
	local notes_lsp = require("notes.lsp")

	original_get_client_by_id = vim.lsp.get_client_by_id
	vim.lsp.get_client_by_id = function() return { name = "ltex_plus" } end

	notes_lsp.setup_code_actions()

	vim.lsp.buf_request_all = function(_, method, _, callback)
		if method == "textDocument/codeAction" then callback({
			[1] = {
				result = {
					{ title = "existing", command = { command = "_ltex.pickLanguage" } },
				},
				context = { client_id = 1 },
			},
		}) end
	end

	local results
	vim.lsp.buf_request_all(0, "textDocument/codeAction", function() return {} end, function(r) results = r end)

	restore_buf_request_all()

	eq(#results[1].result, 1)
end

return T
