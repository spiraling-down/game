-- Ambience Sounds, played according to the current layer
local players = modlib.minetest.playerdata()

minetest.register_globalstep(function()
	for player in modlib.minetest.connected_players() do
		local name = player:get_player_name()
		local data = players[name]
		local layer = map.get_layer(vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0))
		if data.last_layer ~= layer then
			if data.handle then
				minetest.sound_fade(data.handle, 0.5, 0)
			end
			if layer.sound then
				data.handle = minetest.sound_play(layer.sound, {
					to_player = name,
					gain = 1.0,
					fade = 0.5,
					pitch = 1.0,
				}, false)
			end
		end
	end
end)
