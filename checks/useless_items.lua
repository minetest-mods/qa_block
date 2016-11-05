-- Lists all items which are probably useless (not a node, not a weapon, not a mining tool, not used in any crafting recipe).
-- This checker is not perfect and tends to have a couple of false-positives.

local items_in_craft = {}
for k,v in pairs(minetest.registered_items) do
	local recps = minetest.get_all_craft_recipes(k)
	if recps ~= nil then
		for r=1,#recps do
			local recp = recps[r]
			if recp ~= nil and recp.items ~= nil then
				local table_length
				if recp.width == 0 then
					table_length = #recp.items
				else
					table_length = math.pow(recp.width, 2)
				end
				for i=1, table_length do
					if recp.items[i] ~= nil then
						items_in_craft[recp.items[i]] = true
					end
				end
			end
		end
	end
end

local check = function(name, def)
	-- Is it used in ANY crafting recipe?
	if items_in_craft[name] == true then
		return
	end
	-- Is it the hand?
	if name == "" then
		return
	end
	-- Is it a tool?
	if def.tool_capabilities ~= nil then
		-- Mining tool?
		if def.tool_capabilities.groupcaps ~= nil then
			for k, v in pairs(def.tool_capabilities.groupcaps) do
				return
			end
		end
		-- Weapon?
		if def.tool_capabilities.damage_groups ~= nil then
			for k, v in pairs(def.tool_capabilities.damage_groups) do
				return
			end
		end
	end
	-- Are there any callback functions defined?
	-- TODO: Also check on_secondary use, on_place, on_drop
	if def.on_use ~= nil or def.after_use ~= nil then
		return
	end

	-- This item survived all checks, so we print it. It's probably (!) useless.
	print(name)
end

for name, def in pairs(minetest.registered_tools) do
	check(name, def)
end
for name, def in pairs(minetest.registered_craftitems) do
	check(name, def)
end
