--[[
This script does export minetest.registered_items to a *.csv file in world directory
The csv file can further analyzed in libreoffice pivot tables
]]

local filename = minetest.get_worldpath()..'/registered_items.csv'

local expand = "groups"

-- collect keys
local item_attributes = {}
local expand_attributes = {}
for _, item in pairs(minetest.registered_items) do
	for k,v in pairs(item) do
		item_attributes[k] = true
		if k == expand then
			for ek ,ev in pairs(item[expand]) do
				expand_attributes[ek] = true
			end
		end
	end
end

local sep = ','
local file = io.open(filename, "w")


local function format_value(v)
	local value
	if v == nil then
		value = ""
	else
		local t = type(v)
		if t == "number" or t == "string" or t == "boolean" then
			value = dump(v)
		else
			value = t
		end
	end
	return value..sep
end

-- write header line
for k, _ in pairs(item_attributes) do
	print(k)
	if k == expand then
		for kv, _ in pairs(expand_attributes) do
			print(expand..":"..kv)
			file:write(format_value(expand..":"..kv))
		end
	else
		file:write(format_value(k))
	end
end
file:write('\n')

-- write data
for _, item in pairs(minetest.registered_items) do
	for k, _ in pairs(item_attributes) do
		if k == expand then
			for kv, _ in pairs(expand_attributes) do
				file:write(format_value(item[expand][kv]))
			end
		else
			file:write(format_value(item[k]))
		end
	end
	file:write('\n')
end

file:close()

