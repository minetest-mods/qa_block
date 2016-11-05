-- List all nodes for which light_source >= 15
-- light_source 15 is reserved for sunlight. The engine might have issues with this value.

for name, def in pairs(minetest.registered_nodes) do
	if def.light_source >= 15 then
		print(name)
	end
end
