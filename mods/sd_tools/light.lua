local require = modlib.mod.require
local register = require("register")
local lamp = require("lamp")

-- TODO deduplicate with manipulator
local max_uses = 2
local max_wear = 65535
local wear_per_use = math.floor(max_wear / max_uses)

return register("light", {
	_recharge_time = 10,
	description = "Light",
	on_place = function(itemstack, player, pointed_thing)
		if itemstack:get_wear() + wear_per_use > max_wear then
			return
		end
		local current_node = minetest.get_node(pointed_thing.above).name
		if current_node == "air" or current_node == lamp.off then
			if inv.try_decrement_count(player, "lamp") then
				itemstack:add_wear(wear_per_use)
				minetest.set_node(pointed_thing.above, {
					name = lamp.on,
					param2 = minetest.dir_to_wallmounted(pointed_thing.under - pointed_thing.above),
				})
			else
				hud.show_error_message(player, "no lamps")
			end
		end
		return itemstack
	end,
})
