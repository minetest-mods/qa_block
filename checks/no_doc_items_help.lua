-- Checker for the [doc_items]: Lists items without a long description or usage help

local t = {}
for id, def in pairs(minetest.registered_items) do
	if def._doc_items_create_entry ~= false and def.description ~= nil and def.description ~= "" and id ~= "air" and id ~= "ignore" and id ~= "unknown" then
		if (not def._doc_items_longdesc) and (not def._doc_items_usagehelp) then
			table.insert(t, id)
		end
	end
end
table.sort(t)
for i=1, #t do
	print(t[i])
end
