print("initialize Starting QA Block")


minetest.register_node("qa_block:block", {
	description = "Check mods quality starter block",
        tiles = {"default_dirt.png","default_stone.png","default_sand.png"},
        groups = {cracky = 3},
        sounds = default.node_sound_stone_defaults()
})



--qa = {}
--function qa.list_variables(var,recursive)
-------------------------------------------------------------
---- dump variables in tables. can be reduced in dump depth
---- get all variables in memory
----  the top node in LUA is "_G" ;)
--		if recursive == nil then
--			recursive = false
--		end
--
--		for k,v in pairs(var) do
--			print(k,v)
--
--		        if type(v) == "table" and recursive == true  then
--				qa.dump_variables(v,false, "->") 
--			end
--		end
--	end


minetest.register_on_placenode(function (pos, node)
        if node.name == "qa_block:block" then
		print("QA checks started")

--- TODO: some selectoin of executed check
		dofile(minetest.get_modpath("qa_block").."/checks/same_recipe.lua")  
		print("QA checks finished. Have a look to the debug.txt")
		minetest.env:add_node(pos, {name="air"})
        end
end)

