local test = require("mini.test")
local utils = require("notes.utils")
local test_utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality
local p = test_utils.patterns

local T = new_set()

T["normalize"] = new_set()
vim
	.iter({
		{ "converts to lowercase", "HELLO", "hello" },
		{ "replaces spaces with hyphens", "hello world", "hello-world" },
		{ "removes special characters", "Café & bistro", "cafe-bistro" },
		{ "handles accented characters 1", "São Paulo", "sao-paulo" },
		{ "handles accented characters 2", "Tést Title", "test-title" },
		{ "handles umlauts 1", "Müller", "muller" },
		{ "handles umlauts 2", "Straße", "strasse" },
	})
	:each(function(case)
		T["normalize"][case[1]] = function()
			eq(utils.normalize(case[2]), case[3])
		end
	end)

T["create_tags"] = new_set()
vim
	.iter({
		{ "comma-separated", "a, b, c", ",", "#a, #b, #c" },
		{ "trims whitespace", "a ,  b  ,c", ",", "#a, #b, #c" },
		{ "semicolon separator", "one;two;three", ";", "#one, #two, #three" },
	})
	:each(function(case)
		T["create_tags"][case[1]] = function()
			eq(utils.create_tags(case[2], case[3]), case[4])
		end
	end)

T["generate_id"] = new_set()

T["generate_id"]["generates correct length char id"] = function()
	local id = utils.generate_id(4, true)
	eq(#id, 4)
	eq(id:match("^[A-Z]+$") ~= nil, true)
end

T["generate_id"]["generates correct length digit id"] = function()
	local id = utils.generate_id(6)
	eq(#id, 6)
	eq(id:match("^[0-9]+$") ~= nil, true)
end

T["generate_id"]["generates different ids each time"] = function()
	local id1 = utils.generate_id(4, true)
	local id2 = utils.generate_id(4, true)
	eq(#id1, 4)
	eq(#id2, 4)
	eq(id1:match("^[A-Z]+$") ~= nil, true)
	eq(id2:match("^[A-Z]+$") ~= nil, true)
end

T["generate_file_id"] = new_set()

T["generate_file_id"]["returns correct format YYYYMMDDXXXX"] = function()
	local file_id = utils.generate_file_id()
	eq(#file_id, 12)
	eq(file_id:match(p.date_prefix) ~= nil, true)
	eq(file_id:match(p.id_suffix .. "$") ~= nil, true)
end

T["generate_file_id"]["generates different ids each call"] = function()
	local id1 = utils.generate_file_id()
	local id2 = utils.generate_file_id()
	eq(id1:sub(9, 12) ~= id2:sub(9, 12), true)
end

return T
