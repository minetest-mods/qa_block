-- Lists all items without description.

-- Setting the description is optional, but recommended.

for name, def in pairs(minetest.registered_items) do
	-- Hand gets a free pass
	if name ~= "" then
		if (def.description == "" or def.description == nil) and def.groups.not_in_creative_inventory ~= 1 then
			print(name)
		end
	end
end
