-- List all registered fuels (from core.register_craft)

print("Registered fuels:")
local fuels = {}
for itemstring, def in pairs(minetest.registered_items) do
	local input = {
		method = "fuel",
		items = { itemstring },
	}
	local res = minetest.get_craft_result(input)
	if res and res.time > 0 then
		table.insert(fuels, {itemstring, res.time})
	end
end
local sort_by_time = function(v1, v2)
	return v1[2] < v2[2]
end
table.sort(fuels, sort_by_time)
for f=1, #fuels do
	-- Print the fuel name and burntime
	print(string.format("%s (burntime=%d)", fuels[f][1], fuels[f][2]))
end
