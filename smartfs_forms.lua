local fileslist
local smartfs = qa_block.smartfs --use provided


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
			if self.state.location.rootState.location.type == "nodemeta" then
				local savedata = {
						stack = {},
						selected = selected,
					}
				for _, stacknode in ipairs(self.stack) do
					if stacknode.parent then
						table.insert(savedata.stack, stacknode.label)
					end
				end
				local meta = minetest.get_meta(self.state.location.rootState.location.pos)
				meta:set_string("qa_explorer", minetest.serialize(savedata))
			end
		end

		function xp:load_path()
			if self.state.location.rootState.location.type == "nodemeta" then
				local meta = minetest.get_meta(self.state.location.rootState.location.pos)
				local serialized_data = meta:get_string("qa_explorer")
				local savedata
				if serialized_data then
					savedata = minetest.deserialize(serialized_data)
				end
				if savedata and savedata.stack then
					local cursor = _G
					for _, label in ipairs(savedata.stack) do
						if cursor[label] then
							table.insert(self.stack, {
									label = label,
									ref = cursor[label],
									parent = cursor,
									--text =
								})
							cursor = cursor[label]
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


local function _explore_dialog(state)
	state:size(13,7.25)
	state:label(0,0,"header","Explore the Lua environment")
	local lb_stack = state:listbox(0,0.5,5,7,"stack")
	local lb_current = state:listbox(5.5,0.5,7,6.25,"current")
	local btn_dump = state:button(5.5,7,2,0.5,"dump", "Dump")
	local fld_search = state:field(8, 7.32, 2, 0.5, "search")
	local btn_search = state:button(9.7,7,1,0.5,"search_btn", "Search")
	local ck_funchide = state:checkbox(11, 6.75, "funchide", "Hide functions")

	local function update_current(state, index)
		local lb_current = state:get("current")
		local explorer = get_explorer_obj(state)
		local ck_funchide = state:get("funchide")
		local stackentry = explorer.stack[index]
		local search = state:get("search"):getText()
		state.param.explore_search = search
		explorer.list = {}
		if stackentry then
			for name, val in pairs(stackentry.ref) do
				if string.match(name, search) then
					local entry
					local sval
					local t = type(val)
					if t == "number" or t == "string" or t == "boolean" then
						local sval = dump(val)
						if string.len(sval) < 64 then
							entry = name .. ": type \""..t.."\", value: " .. sval
						else
							entry = name .. ": type \""..t.."\", long value"
						end
					elseif t == "function" then
						entry = name .. ": type \""..t.."\",.. source: "..debug.getinfo(val).source
					else
						entry = name .. ": type \""..t.."\""
					end
					if not (ck_funchide:getValue() == true and t == "function") then
						table.insert(explorer.list, {
							label = name,
							ref = val,
							parent = stackentry,
							text = entry
						})
					end
				end
			end
			table.sort(explorer.list, function(a,b)
				return (a.label < b.label)
			end)
			lb_current:clearItems()
			for _, stackentry in ipairs(explorer.list) do
				lb_current:addItem(stackentry.text)
			end
		end
		explorer:save_path(index)
	end

	local explorer = get_explorer_obj(state)
	local selected = explorer:load_path()
	lb_stack:clearItems()
	for _, stacknode in ipairs(explorer.stack) do
		local idx = lb_stack:addItem(stacknode.label)
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
		if not explorer.list[index] then
			return
		end
		if type(explorer.list[index].ref) == "table" then
			local nav_to = explorer.list[index]
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
			local idx = lb_stack:addItem(nav_to.label)
			lb_stack:setSelected(idx)
			explorer.stack[idx] = nav_to
			nav_to.idx = idx
			update_current(state, idx)
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

	btn_search:onClick(function(self, state)
		update_current(state, state:get("stack"):getSelected())
	end)

	state:onInput(function(state, fields, player)
		if state.param.explore_search ~= state:get("search"):getText() then
			update_current(state, state:get("stack"):getSelected())
		end
	end)
end


-----------------------------------------------
-- Root view / tabs
-----------------------------------------------
local function _root_dialog(state)
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
				else
					def.button:setBackground(nil)
					def.view:setVisible(false)
				end
			end
			self.active_name = tabname
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
	tab1.button:onClick(function(self)
		tab_controller:set_active("tab1")
	end)
	tab1.view = state:container(0,1,"tab1_view")
	tab1.viewstate = tab1.view:getContainerState()
	_check_selection_dialog(tab1.viewstate)
	tab_controller:tab_add("tab1", tab1)

	local tab2 = {}
	tab2.button = state:button(2,0,2,1,"tab2_btn","Globals")
	tab2.button:onClick(function(self)
		tab_controller:set_active("tab2")
	end)
	tab2.view = state:container(0,1,"tab2_view")
	tab2.viewstate = tab2.view:getContainerState()
	_explore_dialog(tab2.viewstate)
	tab_controller:tab_add("tab2", tab2)
	if not tab_controller:get_active_name() then
		tab_controller:set_active("tab1")
	end
end


----------------------------------
qa_block.fs = smartfs.create("qa_block:block", _root_dialog)
--------------------------
