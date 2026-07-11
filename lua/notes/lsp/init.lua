--- In-process LSP server that orchestrates ltex-ls-plus.
---
--- Provides a single code action — "Enable spellcheck" / "Disable spellcheck" —
--- that attaches or detaches the real ltex-ls-plus server. When ltex is detached,
--- no other ltex code actions are shown.
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
		cmd = function()
			return {
				request = function(method, params, callback) return utils.dispatch(lsp.handlers, method, params, callback) end,
				notify = function(method, params) return utils.dispatch(lsp.handlers, method, params) end,
				is_closing = function() end,
				terminate = function() end,
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

--- Code action: enable or disable ltex-ls-plus based on current state.
--- @param _ lsp.CodeActionParams
--- @param callback fun(err?: lsp.ResponseError, result: lsp.CodeAction[])
lsp.handlers[Methods.textDocument_codeAction] = function(_, callback)
	local ltex_attached = #vim.lsp.get_clients({ name = "ltex_plus", bufnr = 0 }) > 0
	local title = ltex_attached and "Disable spellcheck (current: enabled)" or "Enable spellcheck (current: disabled)"

	callback(nil, {
		{
			title = title,
			command = {
				title = title,
				command = "notes.toggle_spellcheck",
				arguments = {},
			},
		},
	})
end

--- Execute the toggle spellcheck command.
--- @param _ lsp.ExecuteCommandParams
--- @param callback fun(err?: lsp.ResponseError, result: any)
lsp.handlers[Methods.workspace_executeCommand] = function(_, callback)
	local bufnr = vim.api.nvim_get_current_buf()
	local clients = vim.lsp.get_clients({ name = "ltex_plus", bufnr = bufnr })

	if #clients > 0 then
		clients[1]:stop(true)
	else
		vim.lsp.enable("ltex_plus")
	end

	callback(nil, {})
end

lsp.handlers[Methods.shutdown] = function(_, callback) callback(nil, nil) end

lsp.handlers[Methods.exit] = function(_, callback) callback(nil, nil) end

return lsp
