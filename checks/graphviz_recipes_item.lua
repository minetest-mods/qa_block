local root_item = "default:cobble"
local step_limit = 500

local cache = smart_inventory.cache
local crecipes = smart_inventory.crecipes

local root_name = string.gsub(root_item, ":", "_")

local filename = minetest.get_worldpath().."/recipes"..root_name..".dot"
local file = io.open(filename, "w")

-- header
file:write("digraph G {\nrankdir=LR;\n")
--file:write("digraph G {\n")

-- add the check item to the pipe as analysis entry point
local items_pipe = { root_item }
local touched_items = {[root_item] = true}
local touched_connections = {}

-- process the pipe recursive / till pipe is empty
while items_pipe[1] do
	-- limited recusion
	step_limit = step_limit -1
	if step_limit == 0 then
		break
	end

	local itemname = items_pipe[1]
	local root_name = string.gsub(itemname, ":", "_")
	if not touched_connections[itemname] then
		touched_connections[itemname] = {}
	end

	-- Add recursive sub-entries to the pipe with lower value
	if cache.citems[itemname] and cache.citems[itemname].in_craft_recipe then
		for _, recipe in ipairs(cache.citems[itemname].in_craft_recipe) do
			if crecipes.crecipes[recipe] then

				local child_itemname = crecipes.crecipes[recipe].out_item.name
				local out_name = string.gsub(child_itemname, ":", "_")
				if not touched_connections[itemname][child_itemname] then
					file:write(root_name.." -> "..out_name..";\n")
					touched_connections[itemname][child_itemname] = true
				end

				if not touched_items[child_itemname] then
					touched_items[child_itemname] = true
					table.insert(items_pipe, child_itemname)
				end
			end
		end
	end
	table.remove(items_pipe,1)
end



-- close file
file:write('}\n')
file:close()
