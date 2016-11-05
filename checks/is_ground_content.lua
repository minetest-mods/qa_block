-- This checker lists all nodes for which is_ground_content == true.

--[[ BY DEFAULT, NODES CAN BE DESTROYED BY THE CAVE GENERATOR!
This can be prevented by explicitly setting is_ground_content to false.
It is easy to forget to set is_ground_content=false for the nodes which
would have needed it.

Recommended values for is_ground_content:
- true (default) for any simple node in the ground or underground,
  such as dirt, stone, sand, ores, limestone, orthoclase, etc. Basically
  anything else where caves make sense and it doesn't hurt if the cave
  generator destroy these nodes.
- false for complex nodes, decorational nodes of “artificial” origin,
  interactive nodes, nodes with heavy metadata, “unnatural” nodes, etc.
  Examples: Chests, furnaces, fences, ladders, stone bricks, etc.]]

for name, def in pairs(minetest.registered_nodes) do
	if def.is_ground_content then
		print(name)
	end
end
