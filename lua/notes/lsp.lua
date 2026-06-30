--- Inject client-side ltex actions into the LSP code action menu.
---
--- Neovim's `vim.lsp.buf.code_action` does not consult `client.handlers["textDocument/codeAction"]`
--- (it calls `on_code_action_results` directly). To add a custom code action — like "Pick
--- language" for ltex-ls-plus — we wrap `vim.lsp.buf_request_all` and inject the action into
--- the results before the menu is built.
local notes = {}

local original_buf_request_all
local installed = false

---@param action lsp.CodeAction | lsp.Command
---@return boolean
local function is_pick_language(action) return action.command and action.command.command == "_ltex.pickLanguage" end

---@param results table<integer, { result: lsp.CodeAction[], context: lsp.HandlerContext }>
local function inject_pick_language(results)
	for client_id, result in pairs(results) do
		local client = vim.lsp.get_client_by_id(client_id)
		if client and client.name == "ltex_plus" then
			result.result = result.result or {}
			local already = vim.iter(result.result):any(is_pick_language)
			if not already then table.insert(result.result, {
				title = "Pick language (ltex)",
				kind = "refactor",
				client_id = client_id,
				command = { command = "_ltex.pickLanguage", arguments = {} },
			}) end
		end
	end
end

--- Patch `vim.lsp.buf_request_all` to inject "Pick language" for ltex-ls-plus results.
--- Idempotent — calling this multiple times has no extra effect.
function notes.setup_code_actions()
	if installed then return end
	installed = true

	original_buf_request_all = vim.lsp.buf_request_all
	vim.lsp.buf_request_all = function(bufnr, method, params_fn, callback)
		if method ~= "textDocument/codeAction" or type(callback) ~= "function" then return original_buf_request_all(bufnr, method, params_fn, callback) end
		return original_buf_request_all(bufnr, method, params_fn, function(results)
			inject_pick_language(results)
			callback(results)
		end)
	end
end

--- Undo the patch and reset the installed flag. Intended for tests.
function notes.reset_code_actions()
	if not installed then return end
	installed = false
	if original_buf_request_all then
		vim.lsp.buf_request_all = original_buf_request_all
		original_buf_request_all = nil
	end
end

return notes
