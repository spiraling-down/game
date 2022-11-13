-- Tool effects that have to be applied every globalstep:
--- Recharge tools the player is wielding
--- Deplete tools that are running out of overcharge
--- Run `_on_hold`s for tools the player is wielding & holding dig

-- catchups for fractional wear which might add up for slow recharging
local recharge_catchup = modlib.minetest.playerdata(function()
	return 0
end)
local max_wear = 65535
minetest.register_globalstep(function(dtime)
	for player in modlib.minetest.connected_players() do
		local name = player:get_player_name()
		do -- wielded item handling
			local wielded_item = player:get_wielded_item()
			local holding = player:get_player_control().dig
			local itemdef = minetest.registered_items[wielded_item:get_name()] or {}
			if itemdef._on_hold and holding then
				assert(player:set_wielded_item(itemdef._on_hold(wielded_item, player, dtime) or wielded_item))
			elseif itemdef._recharge_time and (not itemdef._can_recharge or itemdef._can_recharge(wielded_item)) then
				local recharge = dtime / itemdef._recharge_time * max_wear + recharge_catchup[name]
				wielded_item:add_wear(-math.floor(recharge))
				assert(player:set_wielded_item(wielded_item))
				recharge_catchup[name] = recharge % 1
			else
				recharge_catchup[name] = 0
			end
		end
		do -- depletion
			local inventory = player:get_inventory()
			for i = 1, inventory:get_size("main") do
				local stack = inventory:get_stack("main", i)
				local itemdef = minetest.registered_items[stack:get_name()] or {}
				if itemdef._deplete_time then
					-- TODO catchup
					local deplete = dtime / itemdef._deplete_time * max_wear
					local new_wear = math.min(max_wear, stack:get_wear() + math.ceil(deplete))
					stack:set_wear(new_wear)
					if new_wear == max_wear and itemdef._on_deplete then
						stack = itemdef._on_deplete(stack)
					end
					assert(inventory:set_stack("main", i, stack))
				end
			end
		end
	end
end)
