local require = modlib.mod.require
local register = require("register")

local max_wear = 65535
local itemname, itemname_overcharged

itemname = register("drill", {
	description = "Drill",
	on_use = function(itemstack, placer, pointed_thing)
		if itemstack:get_wear() == 0 then -- enable overcharge
			itemstack:set_name(itemname_overcharged)
			return minetest.registered_items[itemname_overcharged].on_use(itemstack, placer, pointed_thing)
		end
		-- TODO dig something
		return itemstack
	end,
	_recharge_time = 30,
})

-- TODO (!) overcharged texture
itemname_overcharged = register("drill_overcharged", {
	description = "Overcharged Drill",
	on_use = function(itemstack, placer, pointed_thing)
		if itemstack:get_wear() == max_wear then -- disable overcharge
			itemstack:set_name(itemname)
			return minetest.registered_items[itemname].on_use(itemstack, placer, pointed_thing)
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
