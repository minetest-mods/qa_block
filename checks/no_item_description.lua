-- Lists all items without description.

-- Setting the description is optional, but recommended.

local t = {}
for name, def in pairs(minetest.registered_items) do
	-- Hand gets a free pass
	if name ~= "" then
		if (def.description == "" or def.description == nil) and def.groups.not_in_creative_inventory ~= 1 then
			table.insert(t, name)
		end
	end
end
table.sort(t)
for i=1, #t do
	print(t[i])
end