return {
	cmd = { "marksman", "server" },
	filetypes = { "markdown" },
	single_file_support = true,
	root_dir = function(fname) return vim.fs.root(fname, { ".marksman.toml" }) or vim.fs.dirname(fname) end,
	on_attach = function(client, bufnr)
		if not vim.g.notes_autoformat then return end
		client.supports_method("textDocument/formatting", { bufnr = bufnr }, function(_, supported)
			if supported then vim.api.nvim_create_autocmd("BufWritePre", {
				buffer = bufnr,
				callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end,
			}) end
		end)
	end,
}
