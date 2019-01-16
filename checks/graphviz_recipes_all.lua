local cache = smart_inventory.cache
local crecipes = smart_inventory.crecipes

local filename = minetest.get_worldpath().."/recipes.dot"
local file = io.open(filename, "w")

-- header
file:write("digraph G {\nrankdir=LR;\n")

-- dependencies
local touched_connections = {}

for itemname, citem in pairs(smart_inventory.cache.citems) do
	local root_name = string.gsub(itemname, ":", "_")
	if not touched_connections[itemname] then
		touched_connections[itemname] = {}
	end
	for _, recipe in ipairs(cache.citems[itemname].in_craft_recipe) do
		if crecipes.crecipes[recipe] then
			local child_itemname = string.gsub(crecipes.crecipes[recipe].out_item.name, ":", "_")
			if not touched_connections[itemname][child_itemname] then
				file:write(root_name.." -> "..child_itemname..";\n")
				touched_connections[itemname][child_itemname] = true
			end
		end
	end
end

-- close file
file:write('}\n')
file:close()
