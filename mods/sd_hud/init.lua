hud = {}

local players = {}

local healthbar_w, healthbar_h = 24, 24

local function get_or_init(player)
	local name = player:get_player_name()
	local res = players[name]
	if res then
		return res
	end
	res = {}
	res.healthbar = player:hud_add({
		hud_elem_type = "statbar",
		position = { x = 0.5, y = 1 },
		text = "heart.png",
		text2 = "heart_gone.png",
		-- NOTE: x2 for full "hearts"
		number = 2 * player:get_hp(),
		item = 2 * minetest.PLAYER_MAX_HP_DEFAULT,
		direction = 0,
		size = { x = healthbar_w, y = healthbar_h },
		offset = { x = -5 * healthbar_w, y = -48 - healthbar_h - 16 },
	})
	players[name] = res
	return res
end

minetest.register_on_joinplayer(function(player)
	get_or_init(player)
end)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

-- HACK using an undocumented, MT-internal function to get access to some events
minetest.register_playerevent(function(player, event)
	local id = get_or_init(player).healthbar
	if event == "health_changed" then
		player:hud_change(id, "number", 2 * player:get_hp())
	elseif event == "properties_changed" then
		player:hud_change(id, "item", 2 * player:get_properties().hp_max)
		player:hud_change(
			id,
			"offset",
			{ x = -player:get_properties().hp_max / 2 * healthbar_w, y = -48 - healthbar_h - 16 }
		)
	end
end)

local errmsg_duration = 1
local errmsg_color = 0xFF0000 -- red
function hud.show_error_message(player, msg)
	local data = get_or_init(player)
	if data.errmsg then
		player:hud_change(data.errmsg.id, "text", msg)
		data.errmsg.remove_job:cancel()
	else
		data.errmsg = {}
		data.errmsg.id = player:hud_add({
			hud_elem_type = "text",
			position = { x = 0.5, y = 1 },
			name = "sd_story:text",
			text = msg,
			number = errmsg_color,
			alignment = { x = 0, y = 0 }, -- centered
			-- HACK hardcoded position above healthbar
			offset = { x = 0, y = -100 },
			size = { x = laf.fontsize, y = 0 },
			z_index = 999, -- below a potential blackscreen
			style = 4, -- mono
		})
	end
	local name = player:get_player_name()
	data.errmsg.remove_job = minetest.after(errmsg_duration, function()
		-- The upvalues are deliberately left unused because in a server setting the player may have left
		local player = minetest.get_player_by_name(name) -- luacheck: ignore
		if not player then
			return
		end
		local data = get_or_init(player) -- luacheck: ignore
		player:hud_remove(assert(data.errmsg.id))
		data.errmsg = nil
	end)
end
