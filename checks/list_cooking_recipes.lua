-- List all registered cooking recipes (from core.register_craft)

print("Registered cooking recipes:")
local recipes = {}
for itemstring, def in pairs(minetest.registered_items) do
	local input = {
		method = "cooking",
		items = { itemstring },
	}
	local res = minetest.get_craft_result(input)
	if res and res.time > 0 then
		table.insert(recipes, {itemstring, res.item, res.time})
	end
end
local sort_by_input = function(v1, v2)
	return v1[1] < v2[1]
end
table.sort(recipes, sort_by_input)
for r=1, #recipes do
	-- Print cooking recipe, displaying the item to be cooked, the item after cooking, and the cook time
	print(string.format("%s -> %s (cooktime=%d)", recipes[r][1], recipes[r][2]:to_string(), recipes[r][3]))
end

