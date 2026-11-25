vim.opt.runtimepath:append(vim.uv.cwd())
package.path = vim.fs.joinpath(vim.uv.cwd(), "lua", "?.lua") .. ";" .. vim.fs.joinpath(vim.uv.cwd(), "lua", "?", "init.lua") .. ";" .. package.path

local mini = vim.env.MINI_NVIM

if not mini then error("MINI_NVIM is not set. Run this config inside devenv.") end

vim.opt.runtimepath:append(mini)

require("mini.test").setup()
require("mini.doc").setup()
