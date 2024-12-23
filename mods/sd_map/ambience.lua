-- Ambience Sounds, played according to the current layer
local layers = modlib.mod.require("layers")
local gen_common = modlib.mod.require("gen_common")

local players = modlib.minetest.playerdata()

local function get_layer(pos)
	gen_common.create_noises(layers)
	local xz = { x = pos.x, y = pos.z }
	local i = 1
	local layer
	repeat
		layer = layers[i]
		local top = math.floor(layer.y_top + layer.noise:get_2d(xz))
		i = i + 1
	until top < pos.y or i == #layers
	return layer._
end

minetest.register_globalstep(function()
	for player in modlib.minetest.connected_players() do
		local name = player:get_player_name()
		local data = players[name]
		local layer = get_layer(vector.offset(player:get_pos(), 0, player:get_properties().eye_height, 0))
		if data.last_layer ~= layer then
			if data.layer_text_hud_id then
				player:hud_change(data.layer_text_hud_id, "text", layer.name)
			else
				data.layer_text_hud_id = player:hud_add({
					hud_elem_type = "text",
					position = { x = 1, y = 0 },
					name = "sd_map:layername",
					text = layer.name,
					number = 0xFFFFFF,
					alignment = { x = -1, y = 1 },
					offset = { x = 0, y = 0 },
					size = { x = 1.25, y = 0 }, -- HACK this ought to be imported properly
					z_index = 1001, -- on top of everything, including a potential blackscreen (by convention)
					style = 4, -- mono
				})
			end
			if data.handle then
				minetest.sound_fade(data.handle, 0.5, 0)
			end
			if layer.sound then
				data.handle = minetest.sound_play(layer.sound, {
					to_player = name,
					gain = 1.0,
					fade = 0.5,
					pitch = 1.0,
					loop = true,
				}, false)
			end
			data.last_layer = layer
		end
	end
end)
