-- List suspicious global variables

--[[ most buildins and known needed globals are blacklisted to not spam
the output. The second blacklist are maybe-known bugs in released
minetest or minetest_game. You can disable the second blacklist if you
need to check the core functionality ]]

local enable_second_blacklist = true

-- Lua needed things https://www.lua.org/manual/5.1/
local blacklist = {
	_G = true,
	_VERSION = true,
	assert = true,
	collectgarbage = true,
	dofile = true,
	error = true,
	getfenv = true,
	getmetatable = true,
	ipairs = true,
	jit = true,
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

	-- undocumented / deprecated in Lua 5.1
	newproxy = true,

-- minetest related needed globals
	minetest = true,
	core = true,
	dump = true,
	dump2 = true,
	Raycast = true,
}

-- part of minetest builtin, but needs to be discussed if it right or wrong
local second_blacklist = {
	PerlinNoise = true,
	PerlinNoiseMap = true,
	VoxelManip = true,
	VoxelArea = true,
	AreaStore = true,
	SecureRandom = true,
	PcgRandom = true,
	PseudoRandom = true,
	ItemStack = true,
	Settings = true,

	cleanup_path = true,
	gcinfo = true,
	on_placenode = true,
	hack_nodes = true,
	file_exists = true,
	nodeupdate = true,
	check_attached_node = true,
	drop_attached_node = true,
	get_last_folder = true,
	spawn_falling_node = true,
	on_dignode = true,
	basic_dump = true,
	nodeupdate_single = true,
	INIT = true,
	DIR_DELIM = true,
	PLATFORM = true,

-- minetest_game
	LIGHT_MAX = true,
	LAVA_VISC = true,
	vector = true,
	WATER_VISC = true,
	WATER_ALPHA = true,
}


local first = true
for name, val in pairs(_G) do
	if minetest.get_modpath(name) then
--		print(name..": mod exists")
	elseif blacklist[name] then -- skip blacklisted
--		print(name..": builtin")
	elseif enable_second_blacklist and second_blacklist[name] then -- skip second blacklisted
--		print(name..": on second blacklist")
	else
		if first then
			print("Suspicious global variables:")
			first = false
		end
		local t = type(val)
		if t == "number" or t == "string" or t == "boolean" then
			local sval = dump(val)
			if string.len(sval) < 64 then
				print(name .. ": type \""..t.."\", value: " .. sval)
			else
				print(name .. ": type \""..t.."\", long value")
			end
		elseif t == "function" then
			print(name .. ": type \""..t.."\",.. source: "..debug.getinfo(val).source)
		else
			print(name .. ": type \""..t.."\"")
		end
	end
end
if first then
	print("No suspicious global variables found.")
end
