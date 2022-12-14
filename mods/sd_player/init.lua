minetest.PLAYER_MAX_HP_DEFAULT = 10

local function init(player)
	player:set_properties({
		hp_max = minetest.PLAYER_MAX_HP_DEFAULT,
		visual = "mesh",
		mesh = "sd_player_mech.obj",
		textures = { "sd_player_mech.png" },
		visual_size = vector.new(1, 1, 1), -- HACK,
		collisionbox = { -0.4, 0, -0.4, 0.4, 1.75, 0.4 },
	})
	assert(player:get_properties().hp_max == minetest.PLAYER_MAX_HP_DEFAULT)
	player:set_armor_groups({ fall_damage_add_percent = -25, fleshy = 100 }) -- reduce fall damage to 75%
	player:set_physics_override({ gravity = 0.5, speed = 1.5 })
end

local function restore(player)
	-- Reset HP
	player:set_hp(minetest.PLAYER_MAX_HP_DEFAULT)
	-- Give initial items
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
	restore(player)
end)
minetest.register_on_respawnplayer(function(player)
	init(player)
	restore(player)
end)
