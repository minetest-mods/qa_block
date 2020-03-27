-- Find crafting recipes which require unknown items or groups

-- If true, will also check groups
local check_groups = true

local modutils = dofile(minetest.get_modpath("qa_block").."/modutils.lua")

local known_bad_items = {}
local known_groups = {}
local known_bad_groups = {}

local function item_exists(itemstring)
	if itemstring == "" then
		return true
	elseif minetest.registered_items[itemstring] then
		return true
	end
	return false
end

local function group_exists(groupname)
	return known_groups[groupname] == true
end

-- Get groups
if check_groups then
	for name, def in pairs(minetest.registered_items) do
		if def.groups then
			for g,r in pairs(def.groups) do
				known_groups[g] = true
			end
		end
	end
end

local check_item = function(itemstring, bad_item_msg, bad_group_msg, is_output)
	local item = ItemStack(itemstring):get_name()
	local modname = modutils.get_modname_by_itemname(item)
	if modname ~= "group" then
		if not item_exists(item) and not known_bad_items[item] then
			known_bad_items[item] = true
			print(bad_item_msg .. ": \"" .. item .. "\"")
		end
	elseif check_groups then
		local groupstr = string.sub(item, 7)
		local groups = string.split(groupstr, ",")
		if is_output and #groups > 0 then
			print(bad_group_msg .. ". Full string: \""..item.."\")")
			return
		end
		for g=1, #groups do
			local group = groups[g]
			if not group_exists(group) and not known_bad_groups[group] then
				print(bad_group_msg .. ": \"" .. group .. "\" (full string: \""..item.."\")")
				known_bad_groups[group] = true
			end
		end
	end
end

-- Check recipes for unknown items and groups
for name, def in pairs(minetest.registered_items) do
	local recipes_for_item = minetest.get_all_craft_recipes(name)
	if recipes_for_item then
		for id, recipe in pairs(recipes_for_item) do
			if recipe.items then
				for i=1, #recipe.items do
					local item = recipe.items[i]
					if item and item ~= "" then
						check_item(item, "Unknown input item", "Input group without any items")
					end
				end
			end
		end
	end
end

