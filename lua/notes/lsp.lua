--- Inject client-side ltex actions into the LSP code action menu.
---
--- Neovim's `vim.lsp.buf.code_action` does not consult `client.handlers["textDocument/codeAction"]`
--- (it calls `on_code_action_results` directly). To add custom code actions — "Pick language"
--- and "Toggle spellcheck" — we wrap `vim.lsp.buf_request_all` and inject them into the
--- results before the menu is built.
local notes = {}
local ltex_data = require("notes.ltex_data")

local original_buf_request_all
local installed = false

--- Read persisted dictionary, disabled rules, and hidden false positives from disk.
---
--- Used by `config.setup` to pre-populate the ltex settings so the server starts
--- with the user's accumulated words/rules instead of an empty state. The
--- `didChangeConfiguration` path is avoided because sending it during `on_attach`
--- cancels ltex's initial document check (see ltex-ls-plus issue: a re-check
--- triggered by the notification preempts the in-flight initial check, and the
--- follow-up check never produces diagnostics before shutdown in short-lived
--- Neovim sessions).
---@return table<string, table<string, string[]>>
function notes.read_persisted_data() return ltex_data.read_all() end

---@param action lsp.CodeAction | lsp.Command
---@return boolean
local function is_pick_language(action) return action.command and action.command.command == "_ltex.pickLanguage" end

---@param action lsp.CodeAction | lsp.Command
---@return boolean
local function is_spellcheck(action) return action.command and action.command.command == "_ltex.spellCheck" end

---@param results table<integer, { result: table[], context: { client_id: integer } }>
local function inject_custom_actions(results)
	for client_id, result in pairs(results) do
		local client = vim.lsp.get_client_by_id(client_id)
		if client and client.name == "ltex_plus" then
			result.result = result.result or {}

			if not vim.iter(result.result):any(is_pick_language) then table.insert(result.result, {
				title = "Pick language",
				kind = "refactor",
				client_id = client_id,
				command = { command = "_ltex.pickLanguage", arguments = {} },
			}) end

			if not vim.iter(result.result):any(is_spellcheck) then
				local spell_enabled = client.config.settings.ltex.spellCheck ~= false
				local title = spell_enabled and "Toggle spellcheck (current: enabled)" or "Toggle spellcheck (current: disabled)"
				table.insert(result.result, {
					title = title,
					kind = "refactor",
					client_id = client_id,
					command = { command = "_ltex.spellCheck", arguments = {} },
				})
			end
		end
	end
end

--- Patch `vim.lsp.buf_request_all` to inject custom actions for ltex-ls-plus results.
--- Idempotent — calling this multiple times has no extra effect.
function notes.setup_code_actions()
	if installed then return end
	installed = true

	original_buf_request_all = vim.lsp.buf_request_all
	vim.lsp.buf_request_all = function(bufnr, method, params_fn, callback)
		if method ~= "textDocument/codeAction" or type(callback) ~= "function" then return original_buf_request_all(bufnr, method, params_fn, callback) end
		return original_buf_request_all(bufnr, method, params_fn, function(results)
			inject_custom_actions(results)
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
