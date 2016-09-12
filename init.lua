print("initialize Starting QA Block")

qa_block = {}

function qa_block.out(...)
	local outsting = ""
	local out
	local x
	for x, out in ipairs(arg) do
		print(out)
		outsting = (outsting..tostring(out)..'\t')
	end
	print(outsting)
	minetest.chat_send_all(outsting)
end


local filepath = minetest.get_modpath("qa_block").."/checks/"
local defaultmodule = "same_recipe"


local function do_module( module )
	qa_block.out("QA checks started")
--- TODO: some selectoin of executed check
	local file = filepath..module..".lua"

	local f=io.open(file,"r")
	if not f then
		qa_block.out("file "..file.." not found")
	else
		io.close(f)
		local compiled
		local executed
		local err
		local compiled, err = loadfile(file)
		if not compiled then
			qa_block.out("syntax error in module file"..file)
			qa_block.out(err)
		else
			executed, err = pcall(compiled)
			if not executed then
				qa_block.out("runtime error appears")
				qa_block.out(err)
			end
		end
	end
	qa_block.out("QA checks finished")

end

minetest.register_chatcommand("qa_block", {
	params = "<checkmodule>",
	description = "Perform qa block check",
	privs = {interact = true},
	func = function(name, param)
	if param and param ~= "" then
		do_module(param)
	else
		do_module(defaultmodule)
	end
	return true, "QA checks finished."
	end,
})

minetest.register_node("qa_block:block", {
	description = "Check mods quality starter block",
        tiles = {"default_dirt.png","default_stone.png","default_sand.png"},
        groups = {cracky = 3},
        sounds = default.node_sound_stone_defaults()
})


minetest.register_on_placenode(function (pos, node)
        if node.name == "qa_block:block" then

--- TODO: some selectoin of executed check
		do_module(defaultmodule)
		minetest.env:add_node(pos, {name="air"})
        end
end)

