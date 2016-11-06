-- List entities that are mobs from mobs_redo or compatible framework

if minetest.global_exists("mobs") and mobs.spawning_mobs then
	for name, def in pairs(mobs.spawning_mobs) do
		print(name)
	end
else
	print("no mobs installed")
end
