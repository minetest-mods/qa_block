-- the smartfs.lua is loaded

--- temporary provide smartfs as builtin, till the needed changes are upstream
local smartfs = qa_block.smartfs
--- temporary end


qa_block.fs = smartfs.create("qa_block:block", function(state)
	state:size(10,7)
	state:label(0,0,"header","Please select a mod check which you want to perform.")
	if state.location.type == "nodemeta" then
		state:label(0,0.5,"header2", "Node position: ".. minetest.pos_to_string(state.location.pos))
	elseif state.location.type == "player" then
		state:label(0,0.5,"header2", "Player: "..state.location.player)
	end
-- Listbox
	local listbox = state:listbox(0,1,10,5.25,"fileslist")
	for idx, file in ipairs(qa_block.get_checks_list()) do
		listbox:addItem(file)
	end

	listbox:onDoubleClick(function(self,state, index)
		qa_block.do_module(self:getItem(index))
	end)

-- Run Button 
	local runbutton = state:button(1,6.5,2,0.5,"Run","Run")
	runbutton:onClick(function(self)
		local check = listbox:getSelectedItem() 
		if check then
			qa_block.do_module(check)
		else
			print("Error: No check module selected.")
		end
	end)
	
	state:button(5,6.5,2,0.5,"Close","Close", true)
	return true
end)
