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

--- temporary provide smartfs as builtin, till the needed changes are upstream
dofile(thismodpath.."/smartfs.lua") --3rd party smarfs
local smartfs = qa_block.smartfs
local smartfsmod = "qa_block"
--- temporary end

--local smartfsmod = minetest.get_modpath("smartfs")
if smartfsmod then --smartfs is optional
	dofile(thismodpath.."/smartfs_forms.lua") --qa_block forms
end

-----------------------------------------------
-- Get insecure environment
-----------------------------------------------
local ie, req_ie = _G, minetest.request_insecure_environment
if req_ie then ie = req_ie() end

-----------------------------------------------
-- QA-Block functionality - list checks
-----------------------------------------------
qa_block.get_checks_list = function()
	if not qa_block.restricted_mode then
		local out = {}
		local files
		files = ie.minetest.get_dir_list(filepath, false)
		for f=1, #files do
			local filename = files[f]
			local outname, _ext = filename:match("(.*)(.lua)$")
			table.insert(out, outname)
		end
		table.sort(out,function(a,b) return a<b end)
		return out
	else
		return qa_block.restricted_cache_checks
	end
end


-----------------------------------------------
-- QA-Block functionality - redefine print - reroute output to chat window
-----------------------------------------------
if print_to_chat then
	local old_print = print
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
-- QA-Block functionality - get the source of a module
-----------------------------------------------
function qa_block.get_source(check)

	if not qa_block.restricted_mode then
		local file = filepath..check..".lua"
		local f=ie.io.open(file,"r")
		if not f then
			return ""
		end
		local content = f:read("*all")
		if not content then
			return ""
		else
			return content
		end
	else
		return qa_block.restricted_cache_source[check]
	end
end

-----------------------------------------------
-- QA-Block functionality - get the source of a module
-----------------------------------------------
function qa_block.do_source(source)
	print("QA checks started.")
	local compiled
	local executed
	local err
	local compiled, err = ie.loadstring(source)
	if not compiled then
		print("Syntax error in QA Block check module")
		print(err)
	else
		executed, err = ie.pcall(compiled)
		if not executed then
			print("Runtime error in QA Block check module!")
			print(err)
		end
	end
	print("QA checks finished.")
end


-----------------------------------------------
-- QA-Block functionality - execute a module
-----------------------------------------------
qa_block.do_module = function(check)
	local source = qa_block.get_source(check)
	if source then
		qa_block.do_source(source)
	end
end

-----------------------------------------------
-- Minetest restricted mode in case of security enabled without trust qa_block
-----------------------------------------------
if not ie then
	print("WARNING: qa_block is not trusted. Starting in restricted compatibility mode")
	qa_block.restricted_cache_checks = qa_block.get_checks_list()

	qa_block.restricted_cache_source = {}
	for idx, check in ipairs(qa_block.restricted_cache_checks) do
		qa_block.restricted_cache_source[check] = qa_block.get_source(check)
	end

	qa_block.restricted_mode = true --enable the restriction
else
	print("qa_block INFO: entering trusted or not restricted environment ;)")
end


-----------------------------------------------
-- Chat command to start checks
-----------------------------------------------
local command_params, command_description
if smartfsmod then
	command_params = "[<check_module> | ls | sel ]"
	command_description = "Perform a mod Quality Assurance check. ls = list available check modules; sel = Open form"
else
	command_params = "[<check_module> | ls ]"
	command_description = "Perform a mod Quality Assurance check. ls = list available check modules"
end

minetest.register_chatcommand("qa", {
	description = command_description,
	params = command_params,
	privs = {server = true},
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
	description = "Quality Assurance block",
	tiles = {"qa_block.png"},
	groups = {cracky = 3, dig_immediate = 2 },
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		if smartfsmod then
			qa_block.fs:attach_nodemeta(pos, placer) --(:form, nodepos, params, placer)
		else --not a smartfs mod selection dialog. Just run the default one
			qa_block.do_module(defaultmodule)
			minetest:remove_node(pos)
		end
	end,
	on_receive_fields = function(pos, formname, fields, sender)
		if smartfsmod then
			smartfs.nodemeta_on_receive_fields(pos, formname, fields, sender)
		end
	end
})
