-- NOTE: This setting is deliberately left undocumented
if minetest.settings:get_bool("sd_enable_devtools") ~= true then
	-- Disable chat & chatcommands
	minetest.registered_on_chat_messages = {
		function(name)
			hud.show_error_message(assert(minetest.get_player_by_name(name)), "there is no one to hear you")
			return true
		end,
	}
	return
end

minetest.register_chatcommand("giveall", {
	params = "[count]",
	description = "Give count (default: 999) many of each resource",
	privs = { server = true },
	func = function(name, param)
		param = modlib.text.trim_spacing(param)
		local count = tonumber(param ~= "" and param or "999")
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

local min, max, total, count = math.huge, -math.huge, 0, 0
for i, on_generated in ipairs(minetest.registered_on_generateds) do
	minetest.registered_on_generateds[i] = function(...)
		local time_us = minetest.get_us_time()
		on_generated(...)
		local dtime_ms = (minetest.get_us_time() - time_us) / 1e3
		min = math.min(min, dtime_ms)
		max = math.max(max, dtime_ms)
		total = total + dtime_ms
		count = count + 1
		local avg = total / count
		minetest.chat_send_all(("on generated: cur: %g; avg: %g; min: %g; max: %g"):format(dtime_ms, avg, min, max))
	end
end
