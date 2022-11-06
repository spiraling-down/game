minetest.register_on_joinplayer(function(player)
	player:hud_set_flags({
		breathbar = false,
		minimap = false,
		minimap_radar = false,
		basic_debug = false,
	})
	player:hud_set_hotbar_itemcount(4)
	player:hud_set_hotbar_image("sd_laf_hotbar.png")
	player:hud_set_hotbar_selected_image("sd_laf_hotbar_selected_slot.png")

	local base_color = "#000821"
	player:set_sky({
		type = "plain",
		base_color = base_color,
		clouds = false,
	})
	player:set_stars({
		count = 250,
		day_opacity = 1,
		star_color = "#FFFFFF33",
		scale = 2,
	})
	player:set_sun({
		sunrise_visible = false, --I have this set to false because the sunrise horizon texture seems buggy with the type="plain" sky
	})
end)

--Animated sun texture:
--
--Animation frames are in the order:
--sun1.png
--sun2.png
--sun3.png
--etc..

local max_frames = 7 --number of frames
local framerate = 5 --frames per second

local time = 0
local frame = 1
minetest.register_globalstep(function(dtime)
	time = time + dtime
	if time > 1 / framerate then
		time = 0
		frame = frame + 1
		if frame > max_frames then
			frame = 1
		end
	end
	for _, player in pairs(minetest.get_connected_players()) do
		player:set_sun({
			texture = "sun" .. frame .. ".png",
		})
	end
end)
