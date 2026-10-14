-- Fix marksman's invalid `**/*.{}` glob (no `.marksman.toml`), which crashes
-- clients that parse it, for example mini.files.
-- https://github.com/artempyanykh/marksman/issues/469
-- Regression test: tests/test_lsp.lua
return {
	cmd = { "marksman", "server" },
	filetypes = { "markdown" },
	single_file_support = true,
	root_markers = { ".marksman.toml", ".git" },
	---@param client vim.lsp.Client
	on_init = function(client)
		local ops = client.server_capabilities.workspace and client.server_capabilities.workspace.fileOperations
		vim.iter(ops or {}):each(function(_, spec)
			vim.iter(spec.filters or {}):each(function(f)
				if f.pattern and f.pattern.glob == "**/*.{}" then f.pattern.glob = "**/*.{md,markdown}" end
			end)
		end)
	end,
}
