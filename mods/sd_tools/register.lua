local modname = minetest.get_current_modname()

return function(name, def)
	def.inventory_image = ("%s_%s.png"):format(modname, name)
	minetest.register_tool(("%s:%s"):format(modname, name), def)
end
