return {
	cmd = { "marksman", "server" },
	filetypes = { "markdown" },
	single_file_support = true,
	root_dir = function(fname) return vim.fs.root(fname, { ".marksman.toml" }) or vim.fs.dirname(fname) end,
}
