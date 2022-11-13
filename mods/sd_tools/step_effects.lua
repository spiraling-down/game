-- Tool effects that have to be applied every globalstep:
--- Recharge tools the player is wielding
--- Deplete tools that are running out of overcharge
--- Run `_on_hold`s for tools the player is wielding & holding dig

-- TODO (!) implement depletion

local recharge_catchup = {} -- catchup for fractional wear which might add up for slow recharging
local max_wear = 65535
minetest.register_globalstep(function(dtime)
	for player in modlib.minetest.connected_players() do
		local name = player:get_player_name()
		local wielded_item = player:get_wielded_item()
		local holding = player:get_player_control().dig
		local itemdef = minetest.registered_items[wielded_item:get_name()] or {}
		if itemdef._on_hold and holding then
			assert(player:set_wielded_item(itemdef._on_hold(wielded_item, player, dtime) or wielded_item))
		elseif itemdef._recharge_time and (not itemdef._can_recharge or itemdef._can_recharge(wielded_item)) then
			local recharge = dtime / itemdef._recharge_time * max_wear + (recharge_catchup[name] or 0)
			wielded_item:add_wear(-recharge)
			assert(player:set_wielded_item(wielded_item))
			recharge_catchup[name] = recharge % 1
		else
			recharge_catchup[name] = nil
		end
	end
end)
