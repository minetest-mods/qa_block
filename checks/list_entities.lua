-- Lists all the registered entities (except builtin)

for id, def in pairs(minetest.registered_entities) do
	-- Ignore builtin entities
	if string.sub(id, 1, 9) ~= "__builtin" then
		print(id)
	end
end
