local radar_dist = 100
local beacon_spread = 300

local human_beacons = {
	"sd_beacons:human_regular",
	"sd_beacons:human_frozen",
	"sd_beacons:human_red",
}
local alien_beacons = {
	"sd_beacons:alien_regular",
	"sd_beacons:alien_frozen",
	"sd_beacons:alien_red",
}

local get_beacon_pos = function(beacon_number, beacon_type)
	local seed
	if beacon_type == "human" then
		seed = minetest.get_mapgen_setting("seed") + beacon_number
	elseif beacon_type == "alien" then
		seed = minetest.get_mapgen_setting("seed") + beacon_number
	end
	local random = PcgRandom(seed)
	--beacons get deeper as you progress
	return vector.new(
		random:next(-beacon_spread, beacon_spread),
		random:next(-beacon_spread / 10 * beacon_number - 50, -beacon_spread / 10 * beacon_number),
		random:next(-beacon_spread, beacon_spread)
	)
end

local get_beacon_type = function(beacon_number)
	return PcgRandom(minetest.get_mapgen_setting("seed") + beacon_number):next(1, 3)
end

local human_beacon_hud_id = nil
local alien_beacon_hud_id = nil

local spawn_beacon = function(beacon_number, beacon_type)
	local pos = get_beacon_pos(beacon_number, beacon_type)
	minetest.emerge_area(pos - vector.new(1, 1, 1), pos + vector.new(1, 1, 1))
	minetest.after(0.5, function()
		if beacon_type == "human" then
			minetest.set_node(pos, { name = human_beacons[get_beacon_type(beacon_number)] })
		else
			minetest.set_node(pos, { name = alien_beacons[get_beacon_type(beacon_number)] })
		end
		minetest.set_node(pos + vector.new(0, 1, 0), { name = "air" })
		minetest.set_node(pos + vector.new(1, 0, 0), { name = "air" })
		minetest.set_node(pos + vector.new(-1, 0, 0), { name = "air" })
		minetest.set_node(pos + vector.new(0, 0, 1), { name = "air" })
		minetest.set_node(pos + vector.new(0, 0, -1), { name = "air" })
	end)
end

--To be called when you get the artifact from the current beacon
local advance_to_next_beacon = function(current_beacon, beacon_type)
	for _, player in pairs(minetest.get_connected_players()) do
		local meta = player:get_meta()
		if beacon_type == "human" then
			meta:set_int("h_current_beacon", current_beacon + 1)
			spawn_beacon(current_beacon + 1, "human")
		elseif beacon_type == "alien" then
			meta:set_int("a_current_beacon", current_beacon + 1)
			spawn_beacon(current_beacon + 1, "alien")
		end
		--Getting the grammar correct
		a_or_an = "a"
		if beacon_type == "alien" then
			a_or_an = "an"
		end

		story.write_text({
			player = player,
			text = "You found " .. a_or_an .. " " .. beacon_type .. " artifact!",
			color = "#000000",
			position = { x = 0.5, y = 0.9 },
			alignment = { x = 0, y = 0 },
		})
	end
end

minetest.register_node("sd_beacons:human_regular", {
	description = "",
	tiles = { "sd_beacons_human_regular.png" },
	groups = { drillable = 2 },
	on_dig = function(pos, node, digger)
		local meta = digger:get_meta()
		advance_to_next_beacon(meta:get_int("h_current_beacon"), "human")
		minetest.set_node(pos, { name = "air" })
		return true
	end,
})
minetest.register_node("sd_beacons:human_frozen", {
	description = "",
	tiles = { "sd_beacons_human_frozen.png" },
	groups = { drillable = 2 },
	on_dig = function(pos, node, digger)
		local meta = digger:get_meta()
		advance_to_next_beacon(meta:get_int("h_current_beacon"), "human")
		minetest.set_node(pos, { name = "air" })
		return true
	end,
})
minetest.register_node("sd_beacons:human_red", {
	description = "",
	tiles = { "sd_beacons_human_red.png" },
	groups = { drillable = 2 },
	on_dig = function(pos, node, digger)
		local meta = digger:get_meta()
		advance_to_next_beacon(meta:get_int("h_current_beacon"), "human")
		minetest.set_node(pos, { name = "air" })
		return true
	end,
})

minetest.register_node("sd_beacons:alien_regular", {
	description = "",
	tiles = { "sd_beacons_alien_regular.png" },
	groups = { drillable = 2 },
	on_dig = function(pos, node, digger)
		local meta = digger:get_meta()
		advance_to_next_beacon(meta:get_int("a_current_beacon"), "alien")
		minetest.set_node(pos, { name = "air" })
		return true
	end,
})
minetest.register_node("sd_beacons:alien_frozen", {
	description = "",
	tiles = { "sd_beacons_alien_frozen.png" },
	groups = { drillable = 2 },
	on_dig = function(pos, node, digger)
		local meta = digger:get_meta()
		advance_to_next_beacon(meta:get_int("a_current_beacon"), "alien")
		minetest.set_node(pos, { name = "air" })
		return true
	end,
})
minetest.register_node("sd_beacons:alien_red", {
	description = "",
	tiles = { "sd_beacons_alien_red.png" },
	groups = { drillable = 2 },
	on_dig = function(pos, node, digger)
		local meta = digger:get_meta()
		advance_to_next_beacon(meta:get_int("a_current_beacon"), "alien")
		minetest.set_node(pos, { name = "air" })
		return true
	end,
})

local setup = function(player)
	player:hud_add({
		hud_elem_type = "image",
		name = "sd_beacons:radar",
		position = { x = 1, y = 1 },
		z_index = 100,
		scale = { x = 3, y = 3 },
		offset = { x = -65 * 3 / 2, y = -65 * 3 / 2 },
		text = "sd_beacons_compass_bg.png",
	})
	human_beacon_hud_id = player:hud_add({
		hud_elem_type = "image",
		name = "sd_beacons:human_beacon_on_compass",
		position = { x = 1, y = 1 },
		z_index = 100,
		scale = { x = 1, y = 1 },
		offset = { x = 0, y = 0 },
		text = "sd_beacons_compass_beacon_white.png^[colorize:#A175A5:alpha",
	})
	alien_beacon_hud_id = player:hud_add({
		hud_elem_type = "image",
		name = "sd_beacons:alien_beacon_on_compass",
		position = { x = 1, y = 1 },
		z_index = 100,
		scale = { x = 1, y = 1 },
		offset = { x = 0, y = 0 },
		text = "sd_beacons_compass_beacon_white.png^[colorize:#FFF103:alpha",
	})
	player:hud_add({
		hud_elem_type = "image",
		name = "sd_beacons:player_pos_on_compass",
		position = { x = 1, y = 1 },
		z_index = 100,
		scale = { x = 0.3, y = 0.3 },
		offset = { x = -70 * 3 / 2, y = -64 * 3 / 2 },
		text = "sd_beacons_compass_beacon_white.png",
	})
	local meta = player:get_meta()
	if meta:get_int("h_current_beacon") == 0 then
		meta:set_int("h_current_beacon", 1)
		spawn_beacon(1, "human")
	else
		spawn_beacon(meta:get_int("h_current_beacon"), "human")
	end
	if meta:get_int("a_current_beacon") == 0 then
		meta:set_int("a_current_beacon", 1)
		spawn_beacon(1, "alien")
	else
		spawn_beacon(meta:get_int("a_current_beacon"), "alien")
	end
end

minetest.register_on_joinplayer(function(player)
	setup(player)
end)

--Beacons get larger on radar as you get closer in depth
local scale_dropoff = function(depth)
	return (3.25 - 2 / (1 + 2 ^ (-0.1 * math.abs(depth)))) * 0.5
end

local ended = false
minetest.register_globalstep(function()
	for _, player in pairs(minetest.get_connected_players()) do
		local meta = player:get_meta()
		local h_current_beacon = meta:get_int("h_current_beacon")
		local human_offset = (get_beacon_pos(h_current_beacon, "human") - player:get_pos()):rotate_around_axis(
			vector.new(0, 1, 0),
			-player:get_look_horizontal()
		)
		local human_depth_scalar = scale_dropoff(human_offset.y)
		if human_offset:length() > radar_dist * 1.41 then
			human_offset = human_offset:normalize() * radar_dist * 1.41
		end
		human_offset.y = 0
		human_offset = human_offset / radar_dist
		human_offset = human_offset * 70 * 3 / 2
		human_offset = human_offset:apply(function(n)
			return math.max(-50 * 3 / 2, math.min(45 * 3 / 2, n))
		end)

		local a_current_beacon = meta:get_int("a_current_beacon")
		local alien_offset = (get_beacon_pos(a_current_beacon, "alien") - player:get_pos()):rotate_around_axis(
			vector.new(0, 1, 0),
			-player:get_look_horizontal()
		)
		local alien_depth_scalar = scale_dropoff(alien_offset.y)
		if alien_offset:length() > radar_dist * 1.41 then
			alien_offset = alien_offset:normalize() * radar_dist * 1.41
		end
		alien_offset.y = 0
		alien_offset = alien_offset / radar_dist
		alien_offset = alien_offset * 70 * 3 / 2
		alien_offset = alien_offset:apply(function(n)
			return math.max(-50 * 3 / 2, math.min(45 * 3 / 2, n))
		end)

		player:hud_change(
			human_beacon_hud_id,
			"offset",
			{ x = human_offset.x - 70 * 3 / 2, y = -human_offset.z - 64 * 3 / 2 }
		)
		player:hud_change(human_beacon_hud_id, "scale", { x = human_depth_scalar, y = human_depth_scalar })
		player:hud_change(
			alien_beacon_hud_id,
			"offset",
			{ x = alien_offset.x - 70 * 3 / 2, y = -alien_offset.z - 64 * 3 / 2 }
		)
		player:hud_change(alien_beacon_hud_id, "scale", { x = alien_depth_scalar, y = alien_depth_scalar })

		--Endgame
		if player:get_pos().y < -500 and not ended then
			ended = true
			--blackscreen copied from sd_story
			player:hud_add({
				hud_elem_type = "image",
				position = { x = 0.5, y = 0.5 },
				name = "sd_beacons:endgame_blackscreen",
				scale = { x = -100, y = -100 },
				text = "blank.png^[colorize:#000:255^[noalpha",
				z_index = 1000,
			})
			if a_current_beacon >= 6 and h_current_beacon <= 4 then
				--Alien Ending
				story.write_text({
					player = player,
					text = "Insert Text for Alien Ending",
					color = "#FFFFFF",
					position = { x = 0.5, y = 0.5 },
					alignment = { x = 0, y = 0 },
				})
			elseif h_current_beacon >= 6 and a_current_beacon <= 4 then
				--Human Ending
				story.write_text({
					player = player,
					text = "Insert Text for Human Ending",
					color = "#FFFFFF",
					position = { x = 0.5, y = 0.5 },
					alignment = { x = 0, y = 0 },
				})
			elseif h_current_beacon >= 6 and a_current_beacon >= 6 then
				--Good Ending
				story.write_text({
					player = player,
					text = "Insert Text for Good Ending",
					color = "#FFFFFF",
					position = { x = 0.5, y = 0.5 },
					alignment = { x = 0, y = 0 },
				})
			else
				--Bad Ending
				story.write_text({
					player = player,
					text = "Insert Text for Bad Ending",
					color = "#FFFFFF",
					position = { x = 0.5, y = 0.5 },
					alignment = { x = 0, y = 0 },
				})
			end
		end
	end
end)
