if mobs and mobs.spawning_mobs then
	for name, def in pairs(mobs.spawning_mobs) do
		print(name)
	end
else
	print("no mobs installed")
end
