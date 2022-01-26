-- Lists items which seem to be unobtainable

--[[ unobtainable by normal means like not dropped or crafted by anything. ]]

local items = {}
for item, _ in pairs(minetest.registered_items) do
	if item ~= "unknown" and item ~= "ignore" and item ~= "air" and item ~= "" then
		items[item] = false
	end
end

for item, def in pairs(minetest.registered_items) do
	if minetest.get_all_craft_recipes(item) ~= nil then
		items[item] = true
	end
	-- Ignore stuff not in creative inventory
	if def.description == nil or def.description == "" or def.groups.not_in_creative_inventory == 1 then
		items[item] = true
	end
	if def.type == "node" then
		if def.drop == nil then
			items[item] = true
		elseif type(def.drop) == "string" and def.drop ~= "" then
			local dropstack = ItemStack(def.drop)
			if not dropstack:is_empty() then
				local dropname = dropstack:get_name()
				items[dropname] = true
			end
		elseif type(def.drop) == "table" and def.drop.items then
			for i=1,#def.drop.items do
				for j=1,#def.drop.items[i].items do 
					items[def.drop.items[i].items[j]] = true
				end
			end
		end
	end
end

for item, obtainable in pairs(items) do
	if obtainable == false then
		print(item)
	end
end
