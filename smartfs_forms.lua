-- the smartfs.lua is loaded

qa_block.fs = smartfs.create("qa_block:block", function(state)

	state:size(10,7)
	state:label(0,0,"header","Please select a qa check and run by doble-click or Run button")
	if state.location.type == "nodemeta" then
		state:label(0,0.5,"header2", "nodemeta: ".. minetest.pos_to_string(state.location.pos))
	else
		state:label(0,0.5,"header2", state.location.type..": "..state.location.player:get_player_name())
	end
-- Listbox
	local listbox = state:listbox(0,1,10,5.5,"fileslist")
	for idx, file in ipairs(qa_block.get_checks_list()) do
		listbox:addItem(file)
	end
	listbox:setSelected(state:getparam("check_selected")) --persist selected item

	listbox:onClick(function(self, state, index)
		state:setparam("check_selected", index)
	end)
	
	listbox:onDoubleClick(function(self,state, index)
		state:setparam("check_selected", index)
		qa_block.do_module(self:getItem(index))
	end)

-- Run Button 
	local runbutton = state:button(1,6.5,2,0.5,"Run","Run")
	runbutton:onClick(function(self)
		local check = listbox:getSelectedItem() 
		if check then
			qa_block.do_module(check)
		else
			print("no check selected")
		end
	end)
	
	state:button(5,6.5,2,0.5,"Cancel","Cancel", true)
	return true
end)
