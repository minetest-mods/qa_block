---------------------------
-- SmartFS: Smart Formspecs
-- License: CC0 or WTFPL
--    by Rubenwardy
---------------------------


-- namespace definition allow the usage of mod implementation in different versions by different mods
-- If the file is loaded directly from an other mod, the namespace is not "smartfs.{}" but "othermod.smartfs.{}" in this case
local currentmod = minetest.get_current_modname() -- mod the file was loaded from
local envroot = nil

if not currentmod or currentmod == "" or --not minetest or something hacky
       currentmod == "smartfs" then      -- or loaded trough smartfs mod
	envroot = _G                         -- populate global
else
	if not _G[currentmod] then
		_G[currentmod] = {}
	end
	envroot = _G[currentmod]
end

envroot.smartfs = {
	_fdef = {},
	_edef = {},
	opened = {},
	inv = {}
}
local smartfs = envroot.smartfs --valid in this file. If the smartfs framework will be splitted to multiple files we need a framework to get envroot in sync


-- the smartfs() function
function smartfs.__call(self, name)
	return smartfs._fdef[name]
end

-- Register forms and elements
function smartfs.create(name,onload)
	if smartfs._fdef[name] then
		error("SmartFS - (Error) Form "..name.." already exists!")
	end
	if smartfs.loaded and not smartfs._loaded_override then
		error("SmartFS - (Error) Forms should be declared while the game loads.")
	end

	smartfs._fdef[name] = {
		_reg = onload,
		name = name,
		show = smartfs._show_,
		attach_nodemeta = smartfs._attach_nodemeta_
	}

	return smartfs._fdef[name]
end
function smartfs.override_load_checks()
	smartfs._loaded_override = true
end

minetest.after(0, function()
	smartfs.loaded = true
end)
function smartfs.dynamic(name,player)
	if not smartfs._dynamic_warned then
		smartfs._dynamic_warned = true
		print("SmartFS - (Warning) On the fly forms are being used. May cause bad things to happen")
	end

	-- obsolete api compatibility to previous versions
	if type(player) == "string" then
		player = minetest.get_player_by_name(player)
	end -- obsolete api compatibility end
	local state = smartfs._makeState_({name=name},player,nil,false)
	state.show = state._show_
	smartfs.opened[player:get_player_name()] = state
	return state
end
function smartfs.element(name,data)
	if smartfs._edef[name] then
		error("SmartFS - (Error) Element type "..name.." already exists!")
	end
	smartfs._edef[name] = data
	return smartfs._edef[name]
end

function smartfs.inventory_mod()
	if unified_inventory then
		return "unified_inventory"
	elseif inventory_plus then
		return "inventory_plus"
	else
		return nil
	end
end

function smartfs.add_to_inventory(form,icon,title)
	if unified_inventory then
		unified_inventory.register_button(form.name, {
			type = "image",
			image = icon,
		})
		unified_inventory.register_page(form.name, {
			get_formspec = function(player, formspec)
				local name = player:get_player_name()
				local opened = smartfs._show_(form, name, nil, true)
				return {formspec = opened:_getFS_(false)}
			end
		})
		return true
	elseif inventory_plus then
		minetest.register_on_joinplayer(function(player)
			inventory_plus.register_button(player, form.name, title)
		end)
		minetest.register_on_player_receive_fields(function(player, formname, fields)
			if formname == "" and fields[form.name] then
				local name = player:get_player_name()
				local opened = smartfs._show_(form, name, nil, true)
				inventory_plus.set_inventory_formspec(player, opened:_getFS_(true))
			end
		end)
		return true
	else
		return false
	end
end

function smartfs._makeState_(form, newplayer, params, is_inv, nodepos)
	-- Create object for monitoring of connected players. If no one connected the state can be free'd
	local _make_players_ = function(form, newplayer)
		local this = {}
		this._list = {} -- players list
		this.connect = function(this,player)
			if player and player:get_player_name() then
				this._list[player:get_player_name()] = player
			end
		end

		this.disconnect = function(this,player)
			if this._list[player:get_player_name()] then
				this._list[player:get_player_name()] = nil
			end
		end

		this.get_first = function(this) --to check if any connected
			return next(this._list)
		end

		this:connect(newplayer)
		return this
	end

	-- create object to handle formspec location
	local _make_location_ = function(form, newplayer, params, is_inv, nodepos)
		local this = {}
		if nodepos then
			this.type = "nodemeta"
			this.pos = nodepos
		elseif newplayer then
			if is_inv then
				this.type = "inventory"
			else
				this.type = "player"
			end
			this.player = newplayer
		end
		return this
	end

	-- create returning state object
	return {
		_ele = {},
		def = form,
		players = _make_players_(form, newplayer),
		location = _make_location_(form, newplayer, params, is_inv, nodepos),
		is_inv = is_inv, -- obsolete. Please use location.type="inventory" instead
		player = newplayer:get_player_name(), -- obsolete. Please use location.player:get_player_name()
		param = params or {},
		get = function(self,name)
			return self._ele[name]
		end,
		close = function(self)
			self.closed = true
		end,
		size = function(self,w,h)
			self._size = {w=w,h=h}
		end,
		_getFS_ = function(self,size)
			local res = ""
			if self._size and size then
				res = "size["..self._size.w..","..self._size.h.."]"
			end
			for key,val in pairs(self._ele) do
				res = res .. val:build()
			end
			return res
		end,
		_show_ = function(self)
			if self.location.type == "inventory" then
				if unified_inventory then
					unified_inventory.set_inventory_formspec(self.location.player, self.def.name)
				elseif inventory_plus then
					inventory_plus.set_inventory_formspec(self.location.player, self:_getFS_(true))
				end
			else
				local res = self:_getFS_(true)
				minetest.show_formspec(self.location.player:get_player_name(), form.name, res)
			end
		end,
		_attach_nodemeta_ = function(self)
			local meta = minetest.env:get_meta(self.location.pos)
			local res = self:_getFS_(true)
			meta:set_string("formspec", res)
			meta:set_string("smartfs_name", self.def.name)
		end,
		-- on Input hook, called before input processing
		onInput = function(self, func)
			self._onInput = func -- state:onInput(fields, player)
		end,
		load = function(self,file)
			local file = io.open(file, "r")
			if file then
				local table = minetest.deserialize(file:read("*all"))
				if type(table) == "table" then
					if table.size then
						self._size = table.size
					end
					for key,val in pairs(table.ele) do
						self:element(val.type,val)
					end
					return true
				end
			end
			return false
		end,
		save = function(self,file)
			local res = {ele={}}

			if self._size then
				res.size = self._size
			end

			for key,val in pairs(self._ele) do
				res.ele[key] = val.data
			end

			local file = io.open(file, "w")
			if file then
				file:write(minetest.serialize(res))
				file:close()
				return true
			end
			return false
		end,
		setparam = function(self,key,value)
			if not key then return end
			self.param[key] = value
			return true
		end,
		getparam = function(self,key,default)
			if not key then return end
			return self.param[key] or default
		end,
		button = function(self,x,y,w,h,name,text,exitf)
			if exitf == nil then exitf = false end
			return self:element("button",{pos={x=x,y=y},size={w=w,h=h},name=name,value=text,closes=exitf})
		end,
		label = function(self,x,y,name,text)
			return self:element("label",{pos={x=x,y=y},name=name,value=text})
		end,
		toggle = function(self,x,y,w,h,name,list)
			return self:element("toggle",{pos={x=x,y=y},size={w=w,h=h},name=name,id=1,list=list})
		end,
		field = function(self,x,y,w,h,name,label)
			return self:element("field",{pos={x=x,y=y},size={w=w,h=h},name=name,value="",label=label})
		end,
		pwdfield = function(self,x,y,w,h,name,label)
			local res = self:element("field",{pos={x=x,y=y},size={w=w,h=h},name=name,value="",label=label})
			res:isPassword(true)
			return res
		end,
		textarea = function(self,x,y,w,h,name,label)
			local res = self:element("field",{pos={x=x,y=y},size={w=w,h=h},name=name,value="",label=label})
			res:isMultiline(true)
			return res
		end,
		image = function(self,x,y,w,h,name,img)
			return self:element("image",{pos={x=x,y=y},size={w=w,h=h},name=name,value=img})
		end,
		checkbox = function(self,x,y,name,label,selected)
			return self:element("checkbox",{pos={x=x,y=y},name=name,value=selected,label=label})
		end,
		listbox = function(self,x,y,w,h,name,selected,transparent)
			return self:element("list", { pos={x=x,y=y}, size={w=w,h=h}, name=name, selected=selected, transparent=transparent })
		end,
		inventory = function(self,x,y,w,h,name)
			return self:element("inventory", { pos={x=x,y=y}, size={w=w,h=h}, name=name })
		end,
		element = function(self,typen,data)
			local type = smartfs._edef[typen]

			if not type then
				error("Element type "..typen.." does not exist!")
			end

			if self._ele[data.name] then
				error("Element "..data.name.." already exists")
			end
			data.type = typen

			local ele = {
				name = data.name,
				root = self,
				data = data,
				remove = function(self)
					self.root._ele[self.name] = nil
				end
			}

			for key,val in pairs(type) do
				ele[key] = val
			end

			self._ele[data.name] = ele

			return self._ele[data.name]
		end
	}
end

-- Show a formspec to a user
function smartfs._show_(form, name, params, is_inv)
	local state = smartfs._makeState_(form, minetest.get_player_by_name(name), params, is_inv)
	state.show = state._show_
	if form._reg(state)~=false then
		if not is_inv then
			smartfs.opened[name] = state
			state:_show_()
		else
			smartfs.inv[name] = state
		end
	end
	return state
end

-- Attach a formspec to a node
function smartfs._attach_nodemeta_(form, nodepos, placer)
	local state = smartfs._makeState_(form, nil, nil, nil, nodepos) --no attached user, no params, no inventory integration
	state:setparam("node_placer", placer)
	if form._reg(state) then
		state:_attach_nodemeta_()
	end
	return state
end

-- Receive fields from formspec
local function _sfs_recieve_(state, player, fields)

	if fields.quit == "true" then
		-- call onInput hook if enabled before exiting
		if state._onInput then
			state:_onInput(fields, player)
		end
		state.players:disconnect(player)
		if state.location.type == "player" then
			smartfs.opened[player:get_player_name()] = nil
		end
		return true
	end

	for key,val in pairs(fields) do
		if state._ele[key] then
			state._ele[key].data.value = val
		end
	end
	for key,val in pairs(state._ele) do
		if val.submit then
			val:submit(fields, player)
		end
	end

	-- call onInput hook if enabled
	if state._onInput then
		state:_onInput(fields, player)
	end

	if not state.closed then
		if state.location.type == "nodemeta" then
			state:_attach_nodemeta_()
		else
			state:_show_()
		end
	else
--		really? I was able to close window trough button_exit[]. Disabled for testing
--		minetest.show_formspec(name,"","size[5,1]label[0,0;Formspec closing not yet created!]")
		state.players:disconnect(player)
		if state.location.type == "player" then
			smartfs.opened[player:get_player_name()] = nil
		end
		return true
	end
	return true
end

-- Receive input from sender to the node form
function smartfs.nodemeta_on_receive_fields(nodepos, formname, fields, sender)

	-- get form info and check if it's a smartfs one
	local meta = minetest.env:get_meta(nodepos)
	local nodeform = meta:get_string("smartfs_name")
	if not nodeform then -- execute only if it is smartfs form
		print("SmartFS - (Warning) smartfs.nodemeta_on_receive_fields for node without smarfs data")
		return false
	end

	-- get the currentsmartfs state
	local opened_id = minetest.pos_to_string(nodepos)
	local state = nil
	local form = smartfs:__call(nodeform)
	if not smartfs.opened[opened_id] or      --if opened first time
	       smartfs.opened[opened_id].def.name ~= nodeform then --or form is changed
		local params = minetest.deserialize(meta:get_string("smartfs_param")) -- param always persist between calls
		state = smartfs._makeState_(form, sender, params, nil, nodepos)
		smartfs.opened[opened_id] = state
		form._reg(state)
	else
		state = smartfs.opened[opened_id]
	end

	-- Set current sender check for multiple users on node
	state.players:connect(sender)

	-- take the input
	_sfs_recieve_(state, sender, fields)

	--persist parameter for later usage
	meta:set_string("smartfs_param", minetest.serialize(state.param))

	if not state.players:get_first() then
		--update formspec on node to a initial one for the next usage (respecting param persistence)
		state._ele = {} --reset the form
		if form._reg(state) then --regen the form
			state:_attach_nodemeta_() --write form to node
		end
		smartfs.opened[opened_id] = nil -- remove the old state
	end
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
	local name = player:get_player_name()
	if smartfs.opened[name] and smartfs.opened[name].location.type == "player" then
		if smartfs.opened[name].def.name == formname then
			local state = smartfs.opened[name]
			return _sfs_recieve_(state,player,fields)
		else
			smartfs.opened[name] = nil
		end
	elseif smartfs.inv[name] and smartfs.inv[name].location.type == "inventory" then
		local state = smartfs.inv[name]
		_sfs_recieve_(state,player,fields)
	end
	return false
end)


-----------------------------------------------------------------
-------------------------  ELEMENTS  ----------------------------
-----------------------------------------------------------------

smartfs.element("button",{
	build = function(self)
		if self.data.img then
			return "image_button["..
				self.data.pos.x..","..self.data.pos.y..
				";"..
				self.data.size.w..","..self.data.size.h..
				";"..
				self.data.img..
				";"..
				self.name..
				";"..
				self.data.value..
				"]"
		else
			if self.data.closes then
				return "button_exit["..
					self.data.pos.x..","..self.data.pos.y..
					";"..
					self.data.size.w..","..self.data.size.h..
					";"..
					self.name..
					";"..
					self.data.value..
					"]"
			else
				return "button["..
					self.data.pos.x..","..self.data.pos.y..
					";"..
					self.data.size.w..","..self.data.size.h..
					";"..
					self.name..
					";"..
					self.data.value..
					"]"
			end
		end
	end,
	submit = function(self, fields, player)
		if fields[self.name] and self._click then
			self:_click(self.root, player)
		end
		if fields[self.name] and self.data.closes then
			self:close()
		end
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setSize = function(self,w,h)
		self.data.size = {w=w,h=h}
	end,
	getSize = function(self,x,y)
		return self.data.size
	end,
	onClick = function(self,func)
		self._click = func
	end,
	click = function(self,func)
		self._click = func
	end,
	setText = function(self,text)
		self.data.value = text
	end,
	getText = function(self)
		return self.data.value
	end,
	setImage = function(self,image)
		self.data.img = image
	end,
	getImage = function(self)
		return self.data.img
	end,
	setClose = function(self,bool)
		self.data.closes = bool
	end
})

smartfs.element("toggle",{
	build = function(self)
		return "button["..
			self.data.pos.x..","..self.data.pos.y..
			";"..
			self.data.size.w..","..self.data.size.h..
			";"..
			self.name..
			";"..
			self.data.list[self.data.id]..
			"]"
	end,
	submit = function(self, fields, player)
		if fields[self.name] then
			self.data.id = self.data.id + 1
			if self.data.id > #self.data.list then
				self.data.id = 1
			end
			if self._tog then
				self:_tog(self.root, player)
			end
		end
	end,
	onToggle = function(self,func)
		self._tog = func
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setSize = function(self,w,h)
		self.data.size = {w=w,h=h}
	end,
	getSize = function(self,x,y)
		return self.data.size
	end,
	setId = function(self,id)
		self.data.id = id
	end,
	getId = function(self)
		return self.data.id
	end,
	getText = function(self)
		return self.data.list[self.data.id]
	end
})

smartfs.element("label",{
	build = function(self)
		return "label["..
			self.data.pos.x..","..self.data.pos.y..
			";"..
			self.data.value..
			"]"
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setText = function(self,text)
		self.data.value = text
	end,
	getText = function(self)
		return self.data.value
	end
})

smartfs.element("field",{
	build = function(self)
		if self.data.ml then
			return "textarea["..
				self.data.pos.x..","..self.data.pos.y..
				";"..
				self.data.size.w..","..self.data.size.h..
				";"..
				self.name..
				";"..
				self.data.label..
				";"..
				self.data.value..
				"]"
		elseif self.data.pwd then
			return "pwdfield["..
				self.data.pos.x..","..self.data.pos.y..
				";"..
				self.data.size.w..","..self.data.size.h..
				";"..
				self.name..
				";"..
				self.data.label..
				"]"
		else
			return "field["..
				self.data.pos.x..","..self.data.pos.y..
				";"..
				self.data.size.w..","..self.data.size.h..
				";"..
				self.name..
				";"..
				self.data.label..
				";"..
				self.data.value..
				"]"
		end
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setSize = function(self,w,h)
		self.data.size = {w=w,h=h}
	end,
	getSize = function(self,x,y)
		return self.data.size
	end,
	setText = function(self,text)
		self.data.value = text
	end,
	getText = function(self)
		return self.data.value
	end,
	isPassword = function(self,bool)
		self.data.pwd = bool
	end,
	isMultiline = function(self,bool)
		self.data.ml = bool
	end
})

smartfs.element("image",{
	build = function(self)
		return "image["..
			self.data.pos.x..","..self.data.pos.y..
			";"..
			self.data.size.w..","..self.data.size.h..
			";"..
			self.data.value..
			"]"
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setSize = function(self,w,h)
		self.data.size = {w=w,h=h}
	end,
	getSize = function(self,x,y)
		return self.data.size
	end,
	setImage = function(self,text)
		self.data.value = text
	end,
	getImage = function(self)
		return self.data.value
	end
})

smartfs.element("checkbox",{
	build = function(self)
		if self.data.value == true then
			self.data.value = "true"
		elseif self.data.value ~= "true" then
			self.data.value = "false"
		end
		return "checkbox["..
			self.data.pos.x..","..self.data.pos.y..
			";"..
			self.name..
			";"..
			self.data.label..
			";"..self.data.value.."]"
	end,
	submit = function(self, fields, player)
		if fields[self.name] then
			-- self.data.value already set by value transfer
			-- call the toggle function if defined
			if self._tog then
				self:_tog(self.root, player)
			end
		end
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setValue = function(self,text)  --true and false
		self.data.value = text
	end,
	getValue = function(self)
		return self.data.value
	end,
	onToggle = function(self,func)
		self._tog = func
	end,
})

smartfs.element("list",{
	build = function(self)
		if not self.data.items then
			self.data.items = {}
		end
		local listformspec = "textlist["..
			self.data.pos.x..","..self.data.pos.y..
			";"..
			self.data.size.w..","..self.data.size.h..
			";"..
			self.data.name..
			";"..
			table.concat(self.data.items, ",")..
			";"..
			tostring(self.data.selected or "")..
			";"..
			tostring(self.data.transparent or "false").."]"

		return listformspec
	end,
	submit = function(self, fields, player)
		if fields[self.name] then
			local _type = string.sub(fields[self.data.name],1,3)
			local index = string.sub(fields[self.data.name],5)
			self.data.selected = index
			if _type == "CHG" and self._click then
				self:_click(self.root, index, player)
			elseif _type == "DCL" and self._doubleClick then
				self:_doubleClick(self.root, index, player)
			end
		end
	end,
	onClick = function(self, func)
		self._click = func
	end,
	click = function(self, func)
		self._click = func
	end,
	onDoubleClick = function(self, func)
		self._doubleClick = func
	end,
	doubleclick = function(self, func)
		self._doubleClick = func
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setSize = function(self,w,h)
		self.data.size = {w=w,h=h}
	end,
	getSize = function(self,x,y)
		return self.data.size
	end,
	addItem = function(self, item)
		if not self.data.items then
			self.data.items = {}
		end
		table.insert(self.data.items, item)
	end,
	removeItem = function(self,idx)
		if not self.data.items then
			self.data.items = {}
		end
		table.remove(self.data.items,idx)
	end,
	getItem = function(self,idx)
		if not self.data.items then
			self.data.items = {}
		end
		if idx then
			return self.data.items[tonumber(idx)]
		else
			return nil
		end
	end,
	popItem = function(self)
		if not self.data.items then
			self.data.items = {}
		end
		local item = self.data.items[#self.data.items]
		table.remove(self.data.items)
		return item
	end,
	setSelected = function(self,idx)
		self.data.selected = idx
	end,
	getSelected = function(self)
		return self.data.selected
	end,
	getSelectedItem = function(self)
		return self:getItem(self:getSelected())
	end,
})

smartfs.element("inventory",{
	build = function(self)
		return "list["..
			(self.data.location or "current_player") ..
			";"..
			self.name..
			";"..
			self.data.pos.x..","..self.data.pos.y..
			";"..
			self.data.size.w..","..self.data.size.h..
			";"..
			(self.data.index or "") ..
			"]"
	end,
	setPosition = function(self,x,y)
		self.data.pos = {x=x,y=y}
	end,
	getPosition = function(self,x,y)
		return self.data.pos
	end,
	setSize = function(self,w,h)
		self.data.size = {w=w,h=h}
	end,
	getSize = function(self,x,y)
		return self.data.size
	end,
	-- available inventory locations
	-- "current_player": Player to whom the menu is shown
	-- "player:<name>": Any player
	-- "nodemeta:<X>,<Y>,<Z>": Any node metadata
	-- "detached:<name>": A detached inventory
	-- "context" does not apply to smartfs, since there is no node-metadata as context available
	setLocation = function(self,location)
		self.data.location = location
	end,
	getLocation = function(self)
		return self.data.location or "current_player"
	end,
	usePosition = function(self, pos)
		self.data.location = string.format("nodemeta:%d,%d,%d", pos.x, pos.y, pos.z)
	end,
	usePlayer = function(self, name)
		self.data.location = "player:" .. name
	end,
	useDetached = function(self, name)
		self.data.location = "detached:" .. name
	end,
	setIndex = function(self,index)
		self.data.index = index
	end,
	getIndex = function(self)
		return self.data.index
	end
})

smartfs.element("code",{
	build = function(self)
		if self._build then
			self:_build()
		end

		return self.data.code
	end,
	submit = function(self, fields, player)
		if self._sub then
			self:_sub(self.root, fields, player)
		end
	end,
	onSubmit = function(self,func)
		self._sub = func
	end,
	onBuild = function(self,func)
		self._build = func
	end,
	setCode = function(self,code)
		self.data.code = code
	end,
	getCode = function(self)
		return self.data.code
	end
})
