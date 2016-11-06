-- Find duplicate crafting recipes

-- resolve groups in recipes during comparing.
-- If enabled the partially overlaps will be found
local enable_groupcheck = false

-- In case the there is a dependency between the mods of overlapped
-- items there is a asumption the overlap is a wanted redefinition.
-- The overlap is not reported in this case
local enable_dependency_check = true

-- print items without recipe in addition
local print_no_recipe = false
-------------

local modutils
if enable_dependency_check then
	modutils = dofile(minetest.get_modpath("qa_block").."/modutils.lua")
end

local function dependency_exists(item1, item2)

	if enable_dependency_check then

		local modname1
		local modname2
		local depmod
		local delimpos

		--the items are from crafting output so maybe the counter needs to be cutted
		delimpos = string.find(item1, " ")
		if delimpos then
			item1 = string.sub(item1, 1, delimpos - 1)
		end

		delimpos = string.find(item2, " ")
		if delimpos then
			item2 = string.sub(item2, 1, delimpos - 1)
		end

		-- check dependency item1 depends on item2
		modname1 = modutils.get_modname_by_itemname(item1)
		modname2 = modutils.get_modname_by_itemname(item2)

		if not modname1 or modname1 == "group" or
		   not modname2 or modname2 == "group" then
			return false
		end

		if modname1 == modname2 then
			return false --there should not be a redefinition in same module
		end
		depmod = modutils.get_depend_checker(modname1)
		if depmod and depmod:check_depend(modname2) then
			return true
		end

		depmod = modutils.get_depend_checker(modname2)
		if depmod and depmod:check_depend(modname1) then
			return true
		end
	else
		return false --no dependency if no check
	end
end

local function is_same_item(item1, item2)

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
			if chkgroup then -- defined from item1, but not the same in simple check
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
						if not dependency_exists(vu.output, vn.output) then
							print('same recipe', vu.output, vn.output)
						end
					end
				end
				table.insert(known_recipes,vn )
			end
		end
	end
end
