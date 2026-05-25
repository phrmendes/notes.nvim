vim.opt.runtimepath:append(vim.uv.cwd())

if #vim.api.nvim_list_uis() == 0 then
	local packages_path = "deps"
	local mini_path = vim.fs.joinpath(packages_path, "pack", "deps", "start", "mini.nvim")

	if not vim.uv.fs_stat(mini_path) then
		local mini_repo = "https://github.com/echasnovski/mini.nvim"
		local out = vim.system({ "git", "clone", "--filter=blob:none", mini_repo, mini_path }):wait()

		if out.code ~= 0 then
			os.exit(1)
		end
	else
		local out = vim.system({ "git", "-C", mini_path, "pull" }):wait()
		if out.code ~= 0 then
			os.exit(1)
		end
	end

	require("mini.test").setup()
	require("mini.doc").setup()
end
