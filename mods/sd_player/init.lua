minetest.PLAYER_MAX_HP_DEFAULT = 10

local function init(player)
	player:set_properties({ hp_max = minetest.PLAYER_MAX_HP_DEFAULT })
	assert(player:get_properties().hp_max == minetest.PLAYER_MAX_HP_DEFAULT)
	player:set_armor_groups({ fall_damage_add_percent = -25, fleshy = 100 }) -- reduce fall damage to 75%
	player:set_physics_override({ gravity = 0.5, speed = 1.5 })
	-- TODO what if this isn't persisted?
	inv.set_count(player, "lamp", 20)
	inv.set_count(player, "steel", 30)
end

minetest.register_on_joinplayer(init)
minetest.register_on_newplayer(function(player)
	do -- adjust inventory list widths
		local inventory = player:get_inventory()
		inventory:set_size("main", 4) -- hotbar-only
		-- Remove crafting-related lists
		inventory:set_size("craft", 0)
		inventory:set_size("craftpreview", 0)
		inventory:set_size("craftresult", 0)
	end
	init(player)
	player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)
end)
minetest.register_on_respawnplayer(init)

-- Hurt sound
minetest.register_on_player_hpchange(function(player, hp_change)
	if hp_change > 0 then
		return
	end
	minetest.sound_play("sd_player_hurt", {
		to_player = player:get_player_name(),
		gain = math.min(1, -hp_change / 2),
		fade = 0,
		pitch = 1.0,
	}, true)
end)

-- TODO player appearance (mech)
