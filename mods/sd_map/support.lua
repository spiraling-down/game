-- Make decorations lacking support (floor or ceiling) fall.
minetest.register_on_dignode(function(pos)
	local pos_above, pos_below = pos:offset(0, 1, 0), pos:offset(0, -1, 0)
	local node_above, node_below = minetest.get_node(pos_above), minetest.get_node(pos_below)
	if minetest.registered_nodes[node_above.name]._support == "floor" then
		minetest.spawn_falling_node(pos_above)
	end
	if minetest.registered_nodes[node_below.name]._support == "ceil" then
		minetest.spawn_falling_node(pos_below)
	end
end)
