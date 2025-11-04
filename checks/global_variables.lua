-- List suspicious global variables

--[[ Most built-in and known global variables are blacklisted to not spam
the output. The first blacklist is for core Lua globals for Lua 5.1.
The second blacklist are for globals added by Luanti (as of 5.14.0).
You can disable the second blacklist if you wish. ]]

local enable_second_blacklist = true

-- Lua-needed things <https://www.lua.org/manual/5.1/>
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
}

-- Luanti-needed things
local second_blacklist = {
	minetest = true,
	core = true,
	dump = true,
	dump2 = true,
	Raycast = true,

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
	ValueNoise = true,
	ValueNoiseMap = true,

	bit = true,
	vector = true,

	INIT = true,
	DIR_DELIM = true,
	PLATFORM = true,
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
