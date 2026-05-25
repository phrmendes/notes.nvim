local test = require("mini.test")
local utils = require("notes.utils")
local test_utils = dofile("tests/utils.lua")
local new_set, eq = test.new_set, test.expect.equality
local p = test_utils.patterns

local T = new_set()

T["normalize"] = new_set()

T["normalize"]["converts to lowercase"] = function()
	eq(utils.normalize("HELLO"), "hello")
end

T["normalize"]["replaces spaces with hyphens"] = function()
	eq(utils.normalize("hello world"), "hello-world")
end

T["normalize"]["removes special characters"] = function()
	eq(utils.normalize("Café & bistro"), "cafe-bistro")
end

T["normalize"]["handles accented characters"] = function()
	eq(utils.normalize("São Paulo"), "sao-paulo")
	eq(utils.normalize("Tést Title"), "test-title")
end

T["normalize"]["handles umlauts"] = function()
	eq(utils.normalize("Müller"), "muller")
	eq(utils.normalize("Straße"), "strasse")
end

T["create_tags"] = new_set()

T["create_tags"]["creates tags from comma-separated string"] = function()
	eq(utils.create_tags("a, b, c", ","), "#a, #b, #c")
end

T["create_tags"]["trims whitespace from tags"] = function()
	eq(utils.create_tags("a ,  b  ,c", ","), "#a, #b, #c")
end

T["create_tags"]["handles semicolon separator"] = function()
	eq(utils.create_tags("one;two;three", ";"), "#one, #two, #three")
end

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
