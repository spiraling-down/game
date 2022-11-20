story = {}

local players = {}

local textcolor = laf.colors.text:to_number_rgb()
local fontsize = laf.fontsize
local chars_per_sec = 5
local msg_keep_factor = 1.5
local blackscreen_fade_duration = 1
local skip_key = "aux1"

local black_tex = "blank.png^[colorize:#000:255^[noalpha"

function story.write_text(params)
	local player, text, color, on_complete, position, offset, alignment =
		params.player, params.text, params.color, params.on_complete, params.position, params.offset, params.alignment
	local name = player:get_player_name()
	local hud_id = player:hud_add({
		hud_elem_type = "text",
		position = position or { x = 0, y = 1 },
		name = "sd_story:text",
		text = "",
		number = color and modlib.minetest.colorspec.from_any(color):to_number_rgb() or textcolor,
		alignment = alignment or { x = 1, y = -1 }, -- right/up
		offset = offset or { x = 0, y = 0 },
		size = { x = fontsize, y = 0 },
		z_index = 1001, -- on top of everything, including a potential blackscreen (by convention)
		style = 4, -- mono
	})
	players[name].text = {
		hud_id = hud_id,
		age = 0,
		text = text,
		on_complete = on_complete or modlib.func.no_op,
	}
end

local function add_blackscreen(player)
	-- TODO do some more? (such as revoking interact; care must be taken to restore it properly though)
	player:set_armor_groups({ immortal = 1 })
	player:set_physics_override({ speed = 0 })
	local name = player:get_player_name()
	local hud_id = player:hud_add({
		hud_elem_type = "image",
		position = { x = 0.5, y = 0.5 },
		name = "sd_story:blackscreen",
		scale = { x = -100, y = -100 }, -- fullscreen
		text = black_tex,
		z_index = 1000, -- on top of everything (by convention)
	})

	local function fade_blackscreen()
		players[name].blackscreen = { hud_id = hud_id, fade_timer = 0 }
	end

	story.write_text({
		player = minetest.get_player_by_name(name),
		text = "Rebooting...",
		color = "green",
		on_complete = fade_blackscreen,
		position = { x = 0.5, y = 0.5 },
		offset = { x = -20, y = 0 },
		alignment = { x = 1, y = -1 },
	})
end

local function remove_blackscreen(player)
	local name = player:get_player_name()
	local data = players[name]
	player:set_armor_groups({ immortal = 0 })
	player:set_physics_override({ speed = 1 })
	player:hud_remove(data.blackscreen.hud_id)
	data.blackscreen = nil
end

local function init(player)
	local name = player:get_player_name()
	players[name] = players[name] or {}
end

-- Start with blackscreen
minetest.register_on_newplayer(function(player)
	init(player)
	add_blackscreen(player)
end)

minetest.register_on_joinplayer(init)

minetest.register_on_leaveplayer(function(player)
	players[player:get_player_name()] = nil
end)

minetest.register_globalstep(function(dtime)
	for player in modlib.minetest.connected_players() do
		local skip = player:get_player_control()[skip_key]
		init(player)
		local data = players[player:get_player_name()]
		local text, blackscreen = data.text, data.blackscreen
		if text then
			local function calc_chars(age)
				return math.min(math.floor(age * chars_per_sec), #text.text)
			end
			local prev_age = text.age
			local prev_chars = calc_chars(prev_age)
			text.age = prev_age + dtime
			local chars = calc_chars(text.age)
			if skip or chars == #text.text and text.age / (chars / chars_per_sec) >= msg_keep_factor then
				player:hud_remove(text.hud_id)
				text.on_complete()
				data.text = nil
			elseif prev_chars ~= chars then
				player:hud_change(text.hud_id, "text", text.text:sub(1, chars))
			end
		end
		if blackscreen then
			blackscreen.fade_timer = blackscreen.fade_timer + dtime
			local opacity = math.floor(255 * (1 - blackscreen.fade_timer / blackscreen_fade_duration))
			if opacity > 0 then
				player:hud_change(blackscreen.hud_id, "text", ("%s^[opacity:%d"):format(black_tex, opacity))
			else
				remove_blackscreen(player)
			end
		end
	end
end)
