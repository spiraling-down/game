local modname = minetest.get_current_modname()

local lamp_nodename = modname .. ":lamp"

minetest.register_node(lamp_nodename, {
	description = "Lamp",
	tiles = { modname .. "_light_lamp.png" },
	walkable = true,
	light_source = 14,
})

return lamp_nodename
