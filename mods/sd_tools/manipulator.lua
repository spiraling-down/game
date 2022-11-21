local require = modlib.mod.require
local register = require("register")
local scaffolding_nodename = require("scaffolding")

local max_uses = 4
local max_wear = 65535
local wear_per_use = math.floor(max_wear / max_uses)

return register("manipulator", {
	_recharge_time = 30,
	description = "Manipulator",
	tool_capabilities = {
		max_drop_level = 0,
		full_punch_interval = 1,
		groupcaps = {
			organics = {
				times = { 0.5, 1, 1.5 },
				uses = 42, -- doesn't matter
			},
		},
		damage_groups = {},
	},
	after_use = function() end, -- don't wear out
	on_place = function(itemstack, player, pointed_thing)
		if itemstack:get_wear() + wear_per_use > max_wear then
			return
		end
		if inv.try_decrement_count(player, "steel") then
			itemstack:add_wear(wear_per_use)
			minetest.item_place(ItemStack(scaffolding_nodename), player, pointed_thing)
		else
			hud.show_error_message(player, "no steel")
		end
		return itemstack
	end,
})
