local blacklist = {

-- Lua needed things https://www.lua.org/manual/5.1/
	_G = true,
	_VERSION = true,
	assert = true,
	collectgarbage = true,
	dofile = true,
	error = true,
	getfenv = true,
	getmetatable = true,
	ipairs = true,
	load = true,
	loadfile = true,
	loadstring = true,
	module = true,
	next = true,
	pairs = true,
	pcall = true,
	print = true,
	rawequal = true,
	rawget = true,
	rawset = true,
	require = true,
	select = true,
	setfenv = true,
	setmetatable = true,
	select = true,
	tonumber = true,
	tostring = true,
	type = true,
	unpack = true,
	xpcall = true,

	coroutine = true,
	debug = true,
	io = true,
	file = true,
	math = true,
	os = true,
	package = true,
	string = true,
	table = true,

-- minetest related needed globals
	minetest = true,
	core = true,
	dump = true,
}

for name, val in pairs(_G) do
	if minetest.get_modpath(name) then
--		print(name, "mod exists")
	elseif blacklist[name] then     -- skip blacklisted
--		print(name, "builtin")
	elseif type(_G[name]) == "function" then -- skip all functions because most of them are builtin
		print(name, "global function")
	else
		print(name, "global variable not in mod namespace!")
	end
end
