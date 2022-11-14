local radar_dist = 100
local beacon_spread = 1000

local get_beacon_pos = function(beacon_number)
	math.randomseed(minetest.get_mapgen_setting("seed") + beacon_number)
	--beacons get deeper as you progress
	return vector.new(
		math.random(-beacon_spread, beacon_spread),
		math.random(-beacon_spread / 10 * beacon_number, 0),
		math.random(-beacon_spread, beacon_spread)
	)
end

local spawn_beacon = function(beacon_number)
	local pos = get_beacon_pos(beacon_number)
	minetest.place_schematic(pos, "beacon_schematic_" .. beacon_number .. ".mts", nil, nil, false)
end

--To be called when you get the artifact from the current beacon
local advance_to_next_beacon = function(current_beacon)
	for _, player in pairs(minetest.get_connected_players()) do
		local meta = player:get_meta()
		meta:set_int("current_beacon", current_beacon + 1)
	end
	spawn_beacon(current_beacon + 1)
end

local beacon_hud_id = nil
minetest.register_on_joinplayer(function(player)
	player:hud_add({
		hud_elem_type = "compass",
		name = "radar",
		position = { x = 0.0, y = 0.5 },
		z_index = 100,
		direction = 1,
		size = { x = 150, y = 150 },
		offset = { x = 100, y = 0 },
		text = "sd_compass_bg.png",
	})
	beacon_hud_id = player:hud_add({
		hud_elem_type = "image",
		name = "beacon_on_compass",
		position = { x = 0.0, y = 0.5 },
		z_index = 100,
		scale = { x = 1, y = 1 },
		offset = { x = 0, y = 0 },
		text = "sd_compass_beacon.png",
	})
	local meta = player:get_meta()
	meta:set_int("current_beacon", 1)
end)

minetest.register_globalstep(function()
	for _, player in pairs(minetest.get_connected_players()) do
		local meta = player:get_meta()
		local current_beacon = meta:get_int("current_beacon")
		local offset = (get_beacon_pos(current_beacon) - player:get_pos()):rotate_around_axis(
			vector.new(0, 1, 0),
			-player:get_look_horizontal()
		)
		offset.y = 0
		if offset:length() > radar_dist then
			offset = offset:normalize()
			player:hud_change(beacon_hud_id, "offset", { x = offset.x * 70 + 100, y = -offset.z * 70 })
		else
			offset = offset / radar_dist
			player:hud_change(beacon_hud_id, "offset", { x = offset.x * 70 + 100, y = -offset.z * 70 })
		end
	end
end)
