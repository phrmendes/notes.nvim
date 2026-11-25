--- In-process LSP server that orchestrates ltex-ls-plus.
---
--- Provides two code actions:
---   - "Enable spellcheck" / "Disable spellcheck" — attaches or detaches ltex-ls-plus.
---   - "Pick language" — opens the language picker (only when ltex is attached).
--- @module "notes.lsp"

local utils = require("notes.lsp.utils")
local Methods = vim.lsp.protocol.Methods

--- @class notes.lsp
local lsp = { handlers = {} }

--- Start the in-process notes server for the given buffer.
--- @param buf integer
--- @return integer? client_id
function lsp.start(buf)
	return vim.lsp.start({
		name = "notes",
		cmd = function(dispatchers)
			local closing = false
			return {
				request = function(method, params, callback) return utils.dispatch(lsp.handlers, method, params, callback) end,
				notify = function(method, params)
					if method == Methods.exit then
						closing = true
						dispatchers.on_exit(0, 15)
						return true
					end
					return utils.dispatch(lsp.handlers, method, params)
				end,
				is_closing = function() return closing end,
				terminate = function() closing = true end,
			}
		end,
	}, { bufnr = buf, silent = true })
end

--- @param _ lsp.InitializeParams
--- @param callback fun(err?: lsp.ResponseError, result: lsp.InitializeResult)
lsp.handlers[Methods.initialize] = function(_, callback)
	callback(nil, {
		serverInfo = { name = "notes", version = "1.0.0" },
		capabilities = {
			codeActionProvider = true,
			executeCommandProvider = { commands = { "notes.toggle_spellcheck" } },
			textDocumentSync = 1,
		},
	})
end

--- Code actions: enable or disable ltex-ls-plus and pick language.
--- @param _ lsp.CodeActionParams
--- @param callback fun(err?: lsp.ResponseError, result: lsp.CodeAction[])
lsp.handlers[Methods.textDocument_codeAction] = function(_, callback)
	local ltex_attached = #vim.lsp.get_clients({ name = "ltex_plus", bufnr = 0 }) > 0
	local title = ltex_attached and "Disable spellcheck (current: enabled)" or "Enable spellcheck (current: disabled)"

	local actions = {
		{
			title = title,
			command = {
				title = title,
				command = "notes.toggle_spellcheck",
				arguments = {},
			},
		},
	}

	if ltex_attached then table.insert(actions, {
		title = "Pick language",
		command = {
			title = "Pick language",
			command = "_ltex.pickLanguage",
			arguments = {},
		},
	}) end

	callback(nil, actions)
end

--- Execute the toggle spellcheck command for the current buffer only.
--- @param _ lsp.ExecuteCommandParams
--- @param callback fun(err?: lsp.ResponseError, result: any)
lsp.handlers[Methods.workspace_executeCommand] = function(_, callback)
	local bufnr = vim.api.nvim_get_current_buf()
	local client = vim.lsp.get_clients({ name = "ltex_plus", bufnr = bufnr })[1]

	if client then
		-- Detach, do not stop: other buffers may share this client.
		vim.lsp.buf_detach_client(bufnr, client.id)
	else
		local ok, err = pcall(vim.lsp.start, vim.lsp.config.ltex_plus, { bufnr = bufnr })
		if not ok then vim.notify("Could not start ltex-ls-plus: " .. tostring(err), vim.log.levels.ERROR) end
	end

	callback(nil, {})
end

lsp.handlers[Methods.shutdown] = function(_, callback) callback(nil, nil) end

return lsp
