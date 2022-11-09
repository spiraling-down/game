return function(...)
	local itemnames = { ... }
	local function set_items(player)
		local inv = player:get_inventory()
		inv:set_size("main", #itemnames)
		inv:set_list("main", itemnames)
	end
	minetest.register_on_newplayer(set_items)
	minetest.register_on_respawnplayer(set_items)
end
