local require = modlib.mod.require
local register = require("register")
local lamp_nodename = require("lamp")

-- TODO deduplicate with manipulator
local max_uses = 50
local max_wear = 65535
local wear_per_use = math.floor(max_wear / max_uses)

return register("light", {
	_recharge_time = 60,
	description = "Light",
	on_place = function(itemstack, placer, pointed_thing)
		if itemstack:get_wear() + wear_per_use > max_wear then
			return
		end
		itemstack:add_wear(wear_per_use)
		minetest.item_place(ItemStack(lamp_nodename), placer, pointed_thing)
		return itemstack
	end,
})
