-- the smartfs.lua is loaded

--- temporary provide smartfs as builtin, till the needed changes are upstream
local smartfs = qa_block.smartfs
--- temporary end


qa_block.fs = smartfs.create("qa_block:block", function(state)
	state:size(10,7)
	state:label(0,0,"header","Please select a qa check and run by doble-click or Run button")
	if state.location.type == "nodemeta" then
		state:label(0,0.5,"header2", "nodemeta: ".. minetest.pos_to_string(state.location.pos))
	else
		state:label(0,0.5,"header2", state.location.type..": "..state.location.player)
	end
-- Listbox
	local listbox = state:listbox(0,1,10,5.5,"fileslist")
	for c=1, #qa_block.checks_list do
		local check = qa_block.checks_list[c]
		local check_label
		if check.description ~= nil then
			check_label = check.description
		else
			check_label = check.id
		end
		listbox:addItem(check_label)
	end

	listbox:onDoubleClick(function(self,state, index)
		local real_index = tonumber(index)
		if real_index ~= nil then
			qa_block.do_module(qa_block.checks_list[real_index].id)
		end
	end)

-- Run Button 
	local runbutton = state:button(1,6.5,2,0.5,"Run","Run")
	runbutton:onClick(function(self)
		local check_id = tonumber(listbox:getSelected())
		if check_id then
			qa_block.do_module(qa_block.checks_list[check_id].id)
		else
			print("no check selected")
		end
	end)
	
	state:button(5,6.5,2,0.5,"Cancel","Cancel", true)
	return true
end)
