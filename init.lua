-----------------------------------------------
-- Some hardcoded settings and constants
-----------------------------------------------
local defaultmodule = "same_recipe"
local print_to_chat = true

-- constants
local modpath = minetest.get_modpath("qa_block")
local filepath = modpath.."/checks/"


-----------------------------------------------
-- Load external libs and other files
-----------------------------------------------
qa_block = {} -- needed as envroot in tools

local thismodpath = minetest.get_modpath(minetest.get_current_modname())
local smartfsmod = minetest.get_modpath("smartfs")

if smartfsmod then --smartfs is optional
	dofile(thismodpath.."/smartfs_forms.lua") --qa_block forms
end

-----------------------------------------------
-- QA-Block functionality - list checks
-----------------------------------------------
qa_block.get_checks_list = function()
	local ls
	local out = {}
	if os.getenv('HOME')~=nil then
		ls = io.popen('ls -a "'..thismodpath..'/checks/"') -- linux/mac native "ls -a"
	else
		ls = io.popen('dir "'..thismodpath..'\\checks\\*.*" /b') --windows native "dir /b"
	end
	for filename in ls:lines() do
		if filename ~= "." and filename ~= ".." then
			local outname, _ext = filename:match("(.*)(.lua)$")
			table.insert(out, outname)
		end
	end

	table.sort(out,function(a,b) return a<b end)
	return out
end


-----------------------------------------------
-- QA-Block functionality - redefine print - reroute output to chat window
-----------------------------------------------
if print_to_chat then
	old_print = print
	print = function(...)
		local outsting = ""
		local out
		local x
		for x, out in ipairs(arg) do
			outsting = (outsting..tostring(out)..'\t')
		end
		old_print(outsting)
		minetest.chat_send_all(outsting)
	end
end


-----------------------------------------------
-- QA-Block functionality - execute a module
-----------------------------------------------
qa_block.do_module = function(module)
	print("QA checks started")
	local file = filepath..module..".lua"

	local f=io.open(file,"r")
	if not f then
		print("file "..file.." not found")
	else
		io.close(f)
		local compiled
		local executed
		local err
		local compiled, err = loadfile(file)
		if not compiled then
			print("syntax error in module file"..file)
			print(err)
		else
			executed, err = pcall(compiled)
			if not executed then
				print("runtime error appears")
				print(err)
			end
		end
	end
	print("QA checks finished")

end

-----------------------------------------------
-- Chat command to start checks
-----------------------------------------------
minetest.register_chatcommand("qa_block", {
	params = "<checkmodule>",
	description = "Perform qa block check",
	privs = {interact = true},
	func = function(name, param)
		if param == "ls" then
			for idx, file in ipairs(qa_block.get_checks_list()) do
				print(file)
			end
		elseif param == "sel" then
			if smartfsmod then
				qa_block.fs:show(name)
			else
				print("selection screen not supported without smartfs")
			end
		elseif param and param ~= "" then
			qa_block.do_module(param)
		else
			qa_block.do_module(defaultmodule)
		end
		return true
	end
})


-----------------------------------------------
-- Block node definition - with optional smartfs integration
-----------------------------------------------
minetest.register_node("qa_block:block", {
	description = "Check mods quality starter block",
	tiles = {"default_dirt.png","default_stone.png","default_sand.png"},
	groups = {cracky = 3},
	sounds = default.node_sound_stone_defaults(),
	on_receive_fields = function(pos, formname, fields, sender)
		if smartfsmod then
			smartfs.nodemeta_on_receive_fields(pos, formname, fields, sender)
		end
	end
})

-----------------------------------------------
-- Block node - start execution trough block placing
-----------------------------------------------
minetest.register_on_placenode(function(pos, newnode, placer, oldnode, itemstack, pointed_thing)
	if newnode.name == "qa_block:block" then
		if smartfsmod then
			qa_block.fs:attach_nodemeta(pos, placer) --(:form, nodepos, params, placer)
		else --not a smartfs mod selection dialog. Just run the default one
			qa_block.do_module(defaultmodule)
			minetest.env:remove_node(pos)
		end
	end
end)
