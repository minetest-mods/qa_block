-----------------------------------------------
-- Some hardcoded settings and constants
-----------------------------------------------
local defaultmodule = "empty"
local print_to_chat = true

-----------------------------------------------
-- Load external libs and other files
-----------------------------------------------
qa_block = {}
qa_block.modpath = minetest.get_modpath(minetest.get_current_modname())
local filepath = qa_block.modpath.."/checks/"

--[[ --temporary buildin usage (again)
local smartfs_enabled = false
if minetest.get_modpath("smartfs") and
		smartfs.nodemeta_on_receive_fields then -- nodemeta handling implemented, right version.
	dofile(qa_block.modpath.."/smartfs_forms.lua")
	smartfs_enabled = true
else
	print("WARNING: qa_block without (compatible) smartfs is limited functionality")
end
]]

local smartfs = dofile(qa_block.modpath.."/smartfs.lua")
qa_block.smartfs = smartfs
dofile(qa_block.modpath.."/smartfs_forms.lua")
local smartfs_enabled = true

-----------------------------------------------
-- QA-Block functionality - list checks
-----------------------------------------------
qa_block.get_checks_list = function()
	local out = {}
	local files
	files = minetest.get_dir_list(filepath, false)
	for f=1, #files do
		local filename = files[f]
		local outname, _ext = filename:match("(.*)(.lua)$")
		table.insert(out, outname)
	end
	table.sort(out,function(a,b) return a<b end)
	return out
end

-----------------------------------------------
-- QA-Block functionality - redefine print - reroute output to chat window
-----------------------------------------------
if print_to_chat then
	local function do_print_redefinition()
		local old_print = print
		print = function(...)
			local outsting = ""
			local out
			local x
			for x, out in ipairs({...}) do
				outsting = (outsting..tostring(out)..'\t')
			end
			old_print(outsting)
			minetest.chat_send_all(outsting)
		end
	end
	minetest.after(0, do_print_redefinition)
end

-----------------------------------------------
-- QA-Block functionality - get the source of a module
-----------------------------------------------
function qa_block.get_source(check)
	local file = filepath..check..".lua"
	local f=io.open(file,"r")
	if not f then
		return ""
	end
	local content = f:read("*all")
	if not content then
		return ""
	else
		return content
	end
end

-----------------------------------------------
-- QA-Block functionality - get the source of a module
-----------------------------------------------
function qa_block.do_source(source, checkname)
	print("QA check "..checkname.." started.")
	local compiled
	local executed
	local err
	local compiled, err = loadstring(source)
	if not compiled then
		print("Syntax error in QA Block check module")
		print(err)
	else
		executed, err = pcall(compiled)
		if not executed then
			print("Runtime error in QA Block check module!")
			print(err)
		end
	end
	print("QA check "..checkname.." finished.")
end

-----------------------------------------------
-- QA-Block functionality - execute a module
-----------------------------------------------
qa_block.do_module = function(check)
	local source = qa_block.get_source(check)
	if source then
		qa_block.do_source(source, check)
	end
end

-----------------------------------------------
-- Chat command to start checks
-----------------------------------------------
local command_params, command_description
if smartfs_enabled then
	command_params = "[<check_module> | help | ls | set <check_module> | ui ]"
	command_description = "Perform a mod Quality Assurance check. see /qa help for details"
else
	command_params = "[<check_module> | help | ls | set <check_module> ]"
	command_description = "Perform a mod Quality Assurance check. see /qa help for details"
end

minetest.register_chatcommand("qa", {
	description = command_description,
	params = command_params,
	privs = {server = true},
	func = function(name, param)
		if param == "help" then
		print([[
- /qa help - print available chat commands
- /qa ls - list all available check modules
- /qa set checkname - set default check
- /qa ui - show selection dialog (smartfs only)
- /qa checkname - run check
- /qa - run default check
		]])
		elseif param == "ls" then
			for idx, file in ipairs(qa_block.get_checks_list()) do
				print(file)
			end
		elseif param == "ui" then
			if smartfs_enabled then
				qa_block.fs:show(name)
			else
				print("selection screen not supported without smartfs")
			end
		elseif string.sub(param, 1, 3) == "set" then
			local isvalid = false
			local option = string.sub(param, 5)
			for idx, file in ipairs(qa_block.get_checks_list()) do
				if file == option then
					isvalid = true
				end
			end
			if isvalid then
				defaultmodule = option
				print("check "..tostring(option).." selected")
			else
				print("check "..tostring(option).." is not valid")
			end
		elseif param and param ~= "" then
			qa_block.do_module(param)
		else
			qa_block.do_module(defaultmodule)
		end
		return true
	end
})


local doc_items_longdesc =
[[The QA block is a quality assurance tool for mod and subgame developers.
By using the block it is possible to:
• Browse trough global Lua variables for deeper insight
• Edit global Lua variables
• Execute ad-hoc Lua code for testing reasons in development
• Run predefined checks for quality assurance
]]

local doc_items_usagehelp =
[[Place the block and open the formspec using right mouse click.
Use the “Globals” tab for browsing trough global Lua variables.
Double-Click to entries to navigate into a table, print long function source or edit numeric or string values
Use the “Checks” tab to run Lua code. Editing the code before running is allowed.
The checks are read from the $MODPATH/checks directory.
It is possible to add new Lua files and run them without restarting the game. Just use the Refresh button.
Ususally the print() command is used in checks, so look in debug.txt or the Minetest console output.
Some chat commands are defined as shortcuts. See “/qa help” for more information.
Please note the “/qa ui” cannot store the current globals navigation, the navigation can be stored in the QA block only.
]]

-----------------------------------------------
-- Block node definition - with optional smartfs integration
-----------------------------------------------
minetest.register_node("qa_block:block", {
	description = "Quality Assurance block",
	tiles = {"qa_block.png"},
	groups = {cracky = 3, dig_immediate = 2 },
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if smartfs_enabled then
			qa_block.fs:attach_to_node(pos)
		else --not a smartfs mod selection dialog. Just run the default one
			qa_block.do_module(defaultmodule)
			minetest.remove_node(pos)
		end
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if smartfs_enabled then
			smartfs.nodemeta_on_receive_fields(pos, formname, fields, sender)
		end
	end,
	_doc_items_longdesc = doc_items_longdesc,
	_doc_items_usagehelp = doc_items_usagehelp,
})
