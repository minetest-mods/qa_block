local fileslist
local smartfs = qa_block.smartfs --use provided
local storage = dofile(qa_block.modpath.."/storage.lua")

-----------------------------------------------
-- Scripts / Checks tab view
-----------------------------------------------
local function update_fileslist(listbox)
	if not fileslist then -- initial update the fileslist
		fileslist = qa_block.get_checks_list()
	end
	listbox:clearItems()
	if fileslist then
		for idx, file in ipairs(fileslist) do
			listbox:addItem(file)
		end
	end
end

local function _check_selection_dialog(state)
	state:size(13,7.25)
	state:label(0,0,"header","Please select a mod check which you want to perform.")
	if state.location.type == "nodemeta" then
		state:label(0,0.5,"header2", "Node position: ".. minetest.pos_to_string(state.location.pos))
	elseif state.location.type == "player" then
		state:label(0,0.5,"header2", "Player: "..state.location.player)
	end

	-- Text area for the info
	local textarea = state:textarea(5.0,1,8,6.25,"textarea","Source")

	-- Listbox
	local listbox = state:listbox(0,1,4.5,5.5,"fileslist")
	update_fileslist(listbox)

	listbox:onClick(function(self, state, index)
		state:get("textarea"):setText(qa_block.get_source(self:getItem(index)))
	end)

	listbox:onDoubleClick(function(self,state, index)
		state:get("textarea"):setText(qa_block.get_source(self:getItem(index)))
		qa_block.do_module(self:getItem(index))
	end)

	-- Run Button
	local runbutton = state:button(10,7,2,0.5,"Run","Run")
	runbutton:onClick(function(self)
		qa_block.do_source(textarea:getText(), "from textarea")
	end)

	-- Refersh Button
	local refreshbutton = state:button(0,7,2,0.5,"refresh","Refresh")
	refreshbutton:onClick(function(self)
		fileslist = qa_block.get_checks_list()
		update_fileslist(state:get("fileslist"))
	end)

	state:button(5,7,2,0.5,"Close","Close", true)
	return true
end

-----------------------------------------------
-- Environment explorer
-----------------------------------------------

local function get_explorer_obj(state)

	local function new_explorer()
		local xp = {
			stack = {
				[1] = {
					label = "Root (_G)",
					ref = _G,
					parent = nil
				},
				list = {}
			},
			state = state,
		}

		function xp:save_path(selected)
			local savedata = {
					stack = {},
					selected = selected,
				}
			for _, stacknode in ipairs(self.stack) do
				local saveentry = { search = stacknode.search }
				if stacknode.parent then
					saveentry.label = stacknode.label
				end
				table.insert(savedata.stack, saveentry)
			end
			state.param.persist.data.qa_explorer = savedata
			state.param.persist:save()
		end

		function xp:restore_path()
			if state.param.persist.data.qa_explorer then
				local savedata = state.param.persist.data.qa_explorer
				if savedata.stack then
					local cursor = _G
					for _, saveentry in ipairs(savedata.stack) do
						if not saveentry.label then -- root node
							self.stack[1].search = saveentry.search
						elseif cursor[saveentry.label] then
							table.insert(self.stack, {
									label = saveentry.label,
									search = saveentry.search,
									ref = cursor[saveentry.label],
									parent = cursor,
									--text =
									--data_type
								})
							cursor = cursor[saveentry.label]
						else
							break
						end
					end
					return savedata.selected
				end
			end
		end

		return xp
	end

	-- get session state reference
	if not state.param._explorer then
		state.param._explorer = new_explorer()
	end
	return state.param._explorer
end

local function clear_string(data, cut_len)
	local len = string.len(data)
	local out = data:gsub("\n", "\\n"):gsub("\t", "\\t")
	if len > cut_len then
		return out:sub(1,cut_len-3).."..."
	else
		return out
	end
end

local function _explore_dialog(state)
	state:size(13,7.25)
	state:label(0,0,"header","Explore the Lua environment")
	local lb_stack = state:listbox(0,0.5,5,7,"stack")
	local lb_current = state:listbox(5.5,0.5,7,6.25,"current")
	local btn_dump = state:button(5.5,7,2,0.5,"dump", "Dump")
	local fld_search = state:field(8, 7.32, 2, 0.5, "search")
	local btn_search = state:button(9.7,7,1,0.5,"search_btn", "Search")
	local ck_funchide = state:checkbox(11, 6.75, "funchide", "Hide functions")
	if state.param.persist.data.explore_funchide then
		ck_funchide:setValue(state.param.persist.data.explore_funchide)
	end

	local function update_current(state, index)
		local lb_current = state:get("current")
		local explorer = get_explorer_obj(state)
		local ck_funchide = state:get("funchide")
		local stackentry = explorer.stack[index]
		explorer.list = {}
		if stackentry then
			state:get("search"):setText(stackentry.search or "")
			for name_raw, val in pairs(stackentry.ref) do
				local name = clear_string(tostring(name_raw),30)
				if string.match(name, stackentry.search or "") then
					local entry
					local t = type(val)
					if t == "number" or t == "string" or t == "boolean" then
						entry = name .. ': type "' .. t .. '", value: ' .. clear_string(dump(val),60)
					elseif t == "function" then
						entry = name .. ': type "' .. t .. '", value: ' .. debug.getinfo(val).source
					else
						entry = name .. ': type "' .. t ..'"'
					end
					if not (ck_funchide:getValue() == true and t == "function") then
						table.insert(explorer.list, {
							label = name,
							ref = val,
							parent = stackentry,
							text = entry,
							data_type = t,
						})
					end
				end
			end
			table.sort(explorer.list, function(a,b)
				return (a.label < b.label)
			end)
			lb_current:clearItems()
			for _, stackentry in ipairs(explorer.list) do
				local color_code = ""
				if stackentry.data_type == "number" then
					color_code = "#FFFF00"
				elseif stackentry.data_type == "string" then
					color_code = "#00FFFF"
				elseif stackentry.data_type == "function" then
					color_code = "#FF00FF"
				elseif stackentry.data_type == "boolean" then
					color_code = "#00FF00"
				elseif stackentry.data_type == "userdata" then
					color_code = "#FF8000"
				elseif stackentry.data_type == "thread" then
					color_code = "#FF0000"
				elseif stackentry.data_type == "table" then
					color_code = "#FFFFFF"
				else -- other
					color_code = "#A0A0A0"
				end
				lb_current:addItem(color_code..stackentry.text)
			end
		end
		state.param.persist.data.explore_funchide = ck_funchide:getValue()
		explorer:save_path(index)
		state.param.persist:save()
	end

	local explorer = get_explorer_obj(state)
	local selected = explorer:restore_path()
	lb_stack:clearItems()
	for _, stacknode in ipairs(explorer.stack) do
		local idx = lb_stack:addItem(clear_string(stacknode.label, 40))
		stacknode.idx = idx
	end
	lb_stack:setSelected(selected)
	lb_stack:onClick(function(self, state, index)
		update_current(state, index)
	end)

	update_current(state, selected)

	ck_funchide:onToggle(function(self, state)
		update_current(state, state:get("stack"):getSelected())
	end)

	lb_current:onDoubleClick(function(self, state, index)
		local explorer = get_explorer_obj(state)
		local lb_stack = state:get("stack")
		local nav_to = explorer.list[index]
		if not nav_to then
			return
		end

		if nav_to.data_type == "table" then
			-- cleanup stack before add the item
			for i = #explorer.stack, 1, -1 do
				if nav_to.parent.idx < explorer.stack[i].idx then
					lb_stack:removeItem(i)
					explorer.stack[i] = nil
				else
					break
				end
			end
			-- add selected to stack and select on stack
			local idx = lb_stack:addItem(clear_string(nav_to.label, 40))
			lb_stack:setSelected(idx)
			explorer.stack[idx] = nav_to
			nav_to.idx = idx
			update_current(state, idx)
		elseif nav_to.data_type == "string" or nav_to.data_type == "number" or nav_to.data_type == "boolean" then
			-- Change the value (string or number)
			local edit_state = state.location.parentState:get("tab3_view"):getContainerState()
			-- press invisible button
			if nav_to.data_type == "string" then
				edit_state:get("tg_type"):setId(1)
			elseif nav_to.data_type == "number" then
				edit_state:get("tg_type"):setId(2)
			elseif nav_to.data_type == "boolean" then
				edit_state:get("tg_type"):setId(3)
			end
			edit_state:get("txt_value"):setText(tostring(nav_to.ref))
			edit_state:setparam("edit_node", nav_to)
			state.location.parentState:get("tab3_btn"):submit()
		else
			-- just print the (maybe) long line
			print(nav_to.text)
		end
	end)

	btn_dump:onClick(function(self, state)
		local index = state:get("current"):getSelected()
		local explorer = get_explorer_obj(state)
		if index and explorer.list[index] then
			print(dump(explorer.list[index].ref))
		end
	end)

	fld_search:setCloseOnEnter(false)
	fld_search:onKeyEnter(function(self, state, player)
		local selected = state:get("stack"):getSelected()
		local stackentry = explorer.stack[selected]
		if stackentry then
			stackentry.search = self:getText()
			update_current(state, selected)
		end
	end)

	btn_search:onClick(function(self, state, player)
		state:get("search"):submit_key_enter("",player)
	end)
end


local function _change_value_dialog(state)
	state:textarea(1, 1, 12, 7, "txt_value", "Value")
	state:button(1,7,2,1,"btn_ok","Update"):onClick(function(self, state, player)
		local lua_node = state:getparam("edit_node")
		local new_value = state:get("txt_value"):getText()
		local toggle = state:get("tg_type"):getId()
		if toggle == 2 then
			new_value = tonumber(new_value)
		elseif toggle == 3 then
			new_value = minetest.is_yes(new_value)
		end
		if new_value == nil then
			print("value conversion failed")
			return
		end
		lua_node.parent.ref[lua_node.label] = new_value

		local list_state = state.location.parentState:get("tab2_view"):getContainerState()
		list_state:get("funchide"):submit() --just trigger the list update
		state.location.parentState:get("tab2_btn"):submit()
	end)

	state:button(3,7,2,1,"btn_cancel","Cancel"):onClick(function(self, state, player)
		state.location.parentState:get("tab2_btn"):submit()
	end)

	state:toggle(5,7,2,1, "tg_type", {"String", "Number", "Boolean"})
end
-----------------------------------------------
-- Root view / tabs
-----------------------------------------------
local function _root_dialog(state)

	state.param.persist = storage.new(state.location)
	state.param.persist:restore()

	--set screen size
	state:size(14,10)
	-- tabbed view controller
	local tab_controller = {
		_tabs = {},
		active_name = nil,
		set_active = function(self, tabname)
			for name, def in pairs(self._tabs) do
				if name == tabname then
					def.button:setBackground("halo.png")
					def.view:setVisible(true)
					self.active_name = tabname
					state.param.persist.data.main_tab = tabname
					state.param.persist:save()
				else
					def.button:setBackground(nil)
					def.view:setVisible(false)
				end
			end
		end,
		tab_add = function(self, name, def)
			def.viewstate:size(14,8) --size of tab view
			self._tabs[name] = def
		end,
		get_active_name = function(self)
			return self.active_name
		end,
	}
	local tab1 = {}
	tab1.button = state:button(0,0,2,1,"tab1_btn","Checks")
	tab1.button:onClick(function(self, state, player)
		tab_controller:set_active("tab1")
		state:get("tab3_btn"):setVisible(false)
	end)
	tab1.view = state:container(0,1,"tab1_view")
	tab1.viewstate = tab1.view:getContainerState()
	_check_selection_dialog(tab1.viewstate)
	tab_controller:tab_add("tab1", tab1)

	local tab2 = {}
	tab2.button = state:button(2,0,2,1,"tab2_btn","Globals")
	tab2.button:onClick(function(self, state, player)
		tab_controller:set_active("tab2")
		state:get("tab3_btn"):setVisible(false)
	end)
	tab2.view = state:container(0,1,"tab2_view")
	tab2.viewstate = tab2.view:getContainerState()
	_explore_dialog(tab2.viewstate)
	tab_controller:tab_add("tab2", tab2)

	local tab3 = {}
	tab3.button = state:button(4,0,2,1,"tab3_btn","Value")
	tab3.button:onClick(function(self, state, player)
		self:setVisible()
		tab_controller:set_active("tab3")
	end)
	tab3.view = state:container(0,1,"tab3_view")
	tab3.viewstate = tab3.view:getContainerState()
	_change_value_dialog(tab3.viewstate)
	tab_controller:tab_add("tab3", tab3)
	tab3.button:setVisible(false)

	if state.param.persist.data.main_tab then
		tab_controller:set_active(state.param.persist.data.main_tab)
	end
	if not tab_controller:get_active_name() then
		tab_controller:set_active("tab1")
	end
end


----------------------------------
qa_block.fs = smartfs.create("qa_block:block", _root_dialog)
--------------------------
