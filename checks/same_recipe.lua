local function is_same_item(item1, item2)

	local enable_groupcheck = false

	local chkgroup = nil
	local chkitem = nil

-- simple check by name (group match is ok/true too)
	if item1 == item2 then --simple check
		return true
	end

	if not item1 or not item2 then -- if one of the items not there => difference
		return false
	end

-- group check
	if enable_groupcheck then
		if item1:sub(1, 6) == "group:" then
			chkgroup = item1:sub(7)
			chkitem  = item2
		end

		if item2:sub(1, 6) == "group:" then
			if  chkgroup then -- defined from item1, but not the same in simple check
				return false
			else
				chkgroup = item2:sub(7)
				chkitem  = item1
			end
		end

		if chkgroup and chkitem then
			local chkitemdef = minetest.registered_nodes[chkitem]
			if not chkitemdef then --should not be happen. But unknown item cannot be in a group
				return false
			elseif chkitemdef.groups[chkgroup] then --is in the group
				return true
			end
		end
	end

	--checks for the same item not passed
	return false
end



local function is_same_recipe(rec1, rec2)
-- Maybe TODO? : recalculation to universal format (width=0). same recipes can be defined in different ways (no samples)
	if not (rec1.items or rec2.items) then  --nill means no recipe that is never the same oO
		return false
	end

	if rec1.type  ~= rec2.type or
	   rec1.width ~= rec2.width then
		return false
	end

	for i =1, 9 do  -- check all fields. max recipe is  3x3e
		if not is_same_item(rec1.items[i], rec2.items[i]) then
			return false
		end
	end
	return true  --checks passed, no differences found
end




local known_recipes = {}
local print_no_recipe = false

-- load and execute file each click
--for name, def in pairs(minetest.registered_nodes) do
for name, def in pairs(minetest.registered_items) do

	if (not def.groups.not_in_creative_inventory or
	   def.groups.not_in_creative_inventory == 0) and
	   def.description and def.description ~= "" then  --check valide entrys only

		local recipes_for_node = minetest.get_all_craft_recipes(name)
		if recipes_for_node == nil then
			if print_no_recipe then
				print(name, "no_recipe")
			end
		else
			for kn, vn in ipairs(recipes_for_node) do
				for ku, vu in ipairs(known_recipes) do
					if vu.output ~= vn.output and
					   is_same_recipe(vu, vn) == true then
						print('same recipe', vu.output, vn.output)
--						print (dump(vu),dump(vn))   --debug
					end
				end
				table.insert(known_recipes,vn )
			end
		end
	end
end
