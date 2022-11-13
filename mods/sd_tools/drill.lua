local require = modlib.mod.require
local register = require("register")

local max_wear = 65535
local itemname, itemname_overcharged

itemname = register("drill", {
	description = "Drill",
	on_use = function(itemstack)
		-- TODO dig something
		return itemstack
	end,
	on_place = function(itemstack, player)
		if inv.try_decrement_count(player, "saturnium") then
			itemstack:set_name(itemname_overcharged)
			return itemstack
		else
			hud.show_error_message(player, "no saturnium")
		end
	end,
	_recharge_time = 30,
})

itemname_overcharged = register("drill_overcharged", {
	description = "Overcharged Drill",
	on_use = function(itemstack, player, pointed_thing)
		if itemstack:get_wear() == max_wear then -- disable overcharge
			itemstack:set_name(itemname)
			return minetest.registered_items[itemname].on_use(itemstack, player, pointed_thing)
		end
		-- TODO dig even more
		return itemstack
	end,
	_deplete_time = 6,
	_on_deplete = function(itemstack)
		itemstack:set_name(itemname)
		return itemstack
	end,
})

return itemname
