-- the smartfs.lua is loaded from init.lua
local smartfs = qa_block.smartfs

local fileslist

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


qa_block.fs = smartfs.create("qa_block:block", function(state)
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
		textarea:setText(qa_block.get_source(self:getItem(index)))
	end)

	listbox:onDoubleClick(function(self,state, index)
		textarea:setText(qa_block.get_source(self:getItem(index)))
		qa_block.do_module(self:getItem(index))
	end)

-- Run Button 
	local runbutton = state:button(10,7,2,0.5,"Run","Run")
	runbutton:onClick(function(self)
		qa_block.do_source(textarea:getText())
	end)

	if not qa_block.restricted_mode then
	-- Refersh Button
		local refreshbutton = state:button(0,7,2,0.5,"refresh","Refresh")
		refreshbutton:onClick(function(self)
			fileslist = qa_block.get_checks_list()
			update_fileslist(listbox)
		end)
	else
		state:label(0,7,"restricted","not trusted fallback mode")
	end

	state:button(5,7,2,0.5,"Close","Close", true)
	return true
end)
