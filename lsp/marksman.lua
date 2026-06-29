return {
	cmd = { "marksman", "server" },
	filetypes = { "markdown" },
	single_file_support = true,
	root_dir = function(bufnr)
		local bufname = vim.api.nvim_buf_get_name(bufnr)
		return vim.fs.root(bufname, { ".marksman.toml" }) or vim.fs.dirname(bufname)
	end,
}
