local storage = {}

function storage.new(location)
	local self = {}
	self.location = location

	function self:save()
		if self.location.type == "nodemeta" then
			local meta = minetest.get_meta(self.location.pos)
			meta:set_string("qa_block_data", minetest.serialize(self.data))
		end
	end

	function self:restore()
		self.data = {}
		if self.location.type == "nodemeta" then
			local meta = minetest.get_meta(self.location.pos)
			local serialized_data = meta:get_string("qa_block_data")
			if serialized_data then
				self.data = minetest.deserialize(serialized_data) or {}
			else
				-- compatibility to first version till 20.03.2017
				serialized_data = meta:get_string("qa_explorer")
				if serialized_data then
					self.data.qa_explorer = minetest.deserialize(serialized_data) or {}
				end
			end
		end
	end

	return self
end

return storage
