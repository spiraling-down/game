minetest.PLAYER_MAX_HP_DEFAULT = 10

local function init(player)
	player:set_properties({ hp_max = minetest.PLAYER_MAX_HP_DEFAULT })
	assert(player:get_properties().hp_max == minetest.PLAYER_MAX_HP_DEFAULT)
	player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)
	player:set_armor_groups({ fall_damage_add_percent = -50 }) -- reduce fall damage by 2x
end

minetest.register_on_joinplayer(init)
minetest.register_on_newplayer(init)
minetest.register_on_respawnplayer(init)

-- TODO player appearance (mech)