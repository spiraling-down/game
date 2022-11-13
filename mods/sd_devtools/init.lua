minetest.register_chatcommand("giveall", {
	params = "[count]",
	description = "Give count (default: 999) many of each resource",
	privs = { server = true },
	func = function(name, param)
		local count = tonumber(param or "999")
		if not count then
			return false, "Invalid count"
		end
		local player = assert(minetest.get_player_by_name(name))
		for _, resource in pairs({
			"saturnium",
			"iron_ore",
			"sand",
			"organics",
			"carbon",
			"steel",
			"glass",
			"acid",
			"lamp",
		}) do
			inv.try_increment_count(player, resource, count)
		end
		return true, "Added resources to inventory."
	end,
})
