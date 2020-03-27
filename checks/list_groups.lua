-- Lists all the groups that items are in

-- If true, will also list all items that are members of the group
local list_group_members = false

local all_groups = {}
for id, def in pairs(minetest.registered_items) do
	if def.groups then
		for group, rating in pairs(def.groups) do
			if rating ~= 0 then
				if not all_groups[group] then
					all_groups[group] = {}
				end
				table.insert(all_groups[group], id)
			end
		end
	end
end

-- Sort groups
local flat_groups = {}
for group, _ in pairs(all_groups) do
	table.insert(flat_groups, group)
end
table.sort(flat_groups)

-- Output
for g=1, #flat_groups do
	local group = flat_groups[g]
	local items = all_groups[group]
	if list_group_members then
		-- Print all groups and the group members
		print("Group \""..group.."\":")
		table.sort(items)
		for i=1, #items do
			-- Print item name and group rating
			local def = minetest.registered_items[items[i]]
			print("  " .. items[i] .. " (" .. def.groups[group]..")")
		end
	else
		-- Print groups only
		print("Group \""..group.."\": "..(#items).." item(s)")
	end
end
