-- Lists all nodes with missing sounds, and which sounds are missing

-- Sounds are always optional, but most nodes SHOULD have sounds for good quality.

for name, def in pairs(minetest.registered_nodes) do
	local complaints = {}
	local failed = false
	-- Air and ignore are allowed to be silent
	if name == "air" or name == "ignore" then
		-- No complaints
	
	-- No sounds at all
	elseif not def.sounds then
		failed = true
		table.insert(complaints, "all")
	else
		-- dig and dug
		if def.pointable and def.diggable then
			if not def.sounds.dug then
				failed = true
				table.insert(complaints, "dug")

				-- dig is implied by dug
				if not def.sounds.dig then
					failed = true
					table.insert(complaints, "dig")
				end
			end
		end
		-- footstep (note: this also works for liquids)
		if def.walkable or def.climbable or def.liquidtype ~= "none" then
			if not def.sounds.footstep then
				failed = true
				table.insert(complaints, "footstep")
			end
		end
		-- place (always complain, because all nodes can be placed)
		if not def.sounds.place then
			failed = true
			table.insert(complaints, "place")
		end
	end
	
	if failed then
		local line = name
		local complaints_string = table.concat(complaints, ", ")
		line = line .. " ("..complaints_string..")"
		print(line)
	end
end
