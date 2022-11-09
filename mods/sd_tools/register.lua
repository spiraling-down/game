local modname = minetest.get_current_modname()

return function(name, def)
	modlib.table.complete(def, {
		inventory_image = ("%s_%s.png"):format(modname, name),
		-- NOTE: No prediction :(
		on_drop = function() end, -- tools can't be dropped
	})
	local itemname = ("%s:%s"):format(modname, name)
	minetest.register_tool(itemname, def)
	return itemname
end
