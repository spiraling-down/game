modlib.mod.require("gen")

local function reposition_player_for_spawn(player)
	local x, z = 0, 0
	local correct_pos = vector.new(x, minetest.get_spawn_level(x, z), z)
	player:set_pos(correct_pos)
end

minetest.register_on_respawnplayer(function(player)
	reposition_player_for_spawn(player)
	return true -- tell Minetest not to reposition the player
end)

minetest.register_on_newplayer(reposition_player_for_spawn)
