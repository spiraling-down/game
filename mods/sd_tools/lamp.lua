local modname = minetest.get_current_modname()

local on_duration = 5 * 60 -- 5 minutes

local function register(variant, def)
	local nodename = ("%s:lamp_%s"):format(modname, variant)
	-- NOTE: Currently unused, but may be useful if made pointable/walkable
	local box = {
		type = "wallmounted",
		wall_bottom = { -0.25, -0.5, -0.25, 0.25, 0.5, 0.25 },
	}
	minetest.register_node(
		nodename,
		modlib.table.complete(def, {
			description = ("Lamp (%s)"):format(variant),
			tiles = { ("%s_light_lamp_%s.png"):format(modname, variant) },
			drawtype = "plantlike",
			paramtype = "light",
			sunlight_propagates = true,
			-- TODO what happens when they lose the node they are mounted to?
			paramtype2 = "wallmounted",
			pointable = false,
			selection_box = box,
			walkable = false,
			collision_box = box,
		})
	)
	return nodename
end

local nodename_off = register("off", {})

local nodename_on = register("on", {
	light_source = 14,
	on_timer = function(pos) -- turn off
		local node = minetest.get_node(pos)
		node.name = nodename_off
		minetest.set_node(pos, node)
	end,
	after_place_node = function(pos)
		local meta = minetest.get_meta(pos)
		meta:set_int("gametime", minetest.get_gametime())
		minetest.get_node_timer(pos):start(on_duration)
	end,
})

minetest.register_lbm({
	label = "Switch off lamps",
	name = ("%s:switch_off_lamps"):format(modname),
	nodenames = { nodename_on },
	run_at_every_load = true,
	action = function(pos)
		local gametime = minetest.get_meta(pos):get_int("gametime")
		local time_left = math.max(0, on_duration - (minetest.get_gametime() - gametime))
		minetest.get_node_timer(pos):start(time_left)
	end,
})

return {
	on = nodename_on,
	off = nodename_off,
}
