local layers = modlib.mod.require("layers")
local gen_common = modlib.mod.require("gen_common")

-- TODO this doesn't take tunnels & caves intersecting the top layer into account
local top_noise
function minetest.get_spawn_level(x, z)
	local top_layer = layers[1]
	top_noise = top_noise or gen_common.create_noise(top_layer)
	return math.max(top_layer.y_top, math.floor(top_layer.y_top + top_noise:get_2d({ x = x, y = z }))) + 0.5
end

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
