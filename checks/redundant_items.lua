-- Lists items which seem to be redundant

--[[ Comparing the second part of the mane ]]

local items = {}

local blacklist = {
	dye = true,
	walls = true,
	xpanes = true,
	wool = true,
}

for item, def in pairs(minetest.registered_items) do
	if item:find(':') then
		local mod_name, item_name = unpack(item:split(':'))
		if not blacklist[mod_name] and not def.groups.not_in_creative_inventory then
			if not items[item_name] then
				items[item_name] = item
			else
				print('Maybe redundant '..item_name, items[item_name], item)
			end
		end
	end
end
