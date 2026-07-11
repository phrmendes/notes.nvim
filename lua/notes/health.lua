--- Health check for notes.nvim
local health = {}

function health.check()
	vim.health.start("notes.nvim")

	local ok, config = pcall(require, "notes.config")
	if not ok then
		vim.health.error("Failed to load notes.config")
		return
	end

	if config.path then
		local stat = vim.uv.fs_stat(config.path)
		if stat and stat.type == "directory" then
			vim.health.ok(string.format("Notes directory exists: %s", config.path))
		else
			vim.health.warn(string.format("Notes directory does not exist: %s", config.path))
		end
	else
		vim.health.error("Notes path not configured: run setup()")
	end

	for _, bin in ipairs({ "marksman", "ltex-ls-plus" }) do
		if vim.fn.executable(bin) == 1 then
			vim.health.ok(string.format("%s found on PATH", bin))
		else
			vim.health.warn(string.format("%s not found on PATH", bin))
		end
	end

	local ltex_path = vim.fs.joinpath(vim.fn.stdpath("data"), "ltex")
	for _, cat in ipairs({ "dictionary", "disabledRules", "hiddenFalsePositives" }) do
		local path = vim.fs.joinpath(ltex_path, cat .. ".json")
		local stat = vim.uv.fs_stat(path)
		if stat then
			local size = stat.size or 0
			vim.health.ok(string.format("%s: %d bytes", cat, size))
		else
			vim.health.info(string.format("No %s file yet (first use)", cat))
		end
	end

	vim.health.info("LSP attachment is buffer-scoped; diagnostics appear after attaching to a markdown/tex buffer")
end

return health
