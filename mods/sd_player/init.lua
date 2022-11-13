minetest.PLAYER_MAX_HP_DEFAULT = 10

local function init(player)
	player:set_properties({ hp_max = minetest.PLAYER_MAX_HP_DEFAULT })
	assert(player:get_properties().hp_max == minetest.PLAYER_MAX_HP_DEFAULT)
	player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)
	player:set_armor_groups({ fall_damage_add_percent = -50 }) -- reduce fall damage by 2x
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
	-- TODO what if this isn't persisted?
	inv.set_count(player, "lamp", 20)
	inv.set_count(player, "steel", 30)
end)
minetest.register_on_respawnplayer(init)

-- TODO player appearance (mech)
