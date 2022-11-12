local ids = {}

local w, h = 24, 24

local function init_healthbar(player)
	ids[player:get_player_name()] = player:hud_add({
		hud_elem_type = "statbar",
		position = { x = 0.5, y = 1 },
		text = "heart.png",
		text2 = "heart_gone.png",
		-- NOTE: x2 for full "hearts"
		number = 2 * minetest.PLAYER_MAX_HP_DEFAULT,
		item = 2 * minetest.PLAYER_MAX_HP_DEFAULT,
		direction = 0,
		size = { x = w, y = h },
		offset = { x = -5 * w, y = -48 - h - 16 },
	})
end

minetest.register_on_joinplayer(init_healthbar)

minetest.register_on_leaveplayer(function(player)
	ids[player:get_player_name()] = nil
end)

-- HACK using an undocumented, MT-internal function to get access to some events
minetest.register_playerevent(function(player, event)
	local id = ids[player:get_player_name()]
	if not id then
		init_healthbar(player)
		id = ids[player:get_player_name()]
	end
	if event == "health_changed" then
		player:hud_change(id, "number", 2 * player:get_hp())
	elseif event == "properties_changed" then
		player:hud_change(id, "item", 2 * player:get_properties().hp_max)
		player:hud_change(id, "offset", { x = -player:get_properties().hp_max / 2 * w, y = -48 - h - 16 })
	end
end)
