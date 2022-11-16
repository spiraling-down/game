local require = modlib.mod.require
local register = require("register")

local itemname, itemname_overcharged

local function on_secondary_use(itemstack, player)
	if itemstack:get_wear() > 0 then
		return
	end
	if inv.try_decrement_count(player, "saturnium") then
		itemstack:set_name(itemname_overcharged)
		return itemstack
	else
		hud.show_error_message(player, "no saturnium")
	end
end

itemname = register("drill", {
	description = "Drill",
	tool_capabilities = {
		max_drop_level = 0,
		full_punch_interval = 1,
		groupcaps = {
			drillable = {
				times = { 0.5, 1, 1.5 },
				uses = 42, -- doesn't matter
			},
		},
		damage_groups = {},
	},
	after_use = function() end, -- don't wear out
	on_place = on_secondary_use,
	on_secondary_use = on_secondary_use,
	_recharge_time = 30,
})

local digging = modlib.minetest.playerdata()

local overcharged_tool_caps = {
	max_drop_level = 0,
	full_punch_interval = 0.5,
	groupcaps = {
		drillable = {
			times = { 0.25, 0.5, 0.75 },
			uses = 0, -- doesn't matter
		},
	},
	damage_groups = {},
}

local function cancel_digging(player)
	local dig_actions = digging[player:get_player_name()]
	if not dig_actions then
		return
	end
	for i, dig_action in modlib.table.rpairs(dig_actions) do
		minetest.delete_particlespawner(dig_action.particlespawner_id)
		dig_action.job:cancel()
		dig_actions[i] = nil
	end
end

local function dig_node(pos, player)
	local oldnode = minetest.get_node(pos)
	local def = minetest.registered_nodes[oldnode.name]
	local on_dig = def.on_dig or minetest.node_dig
	local success = on_dig(pos, oldnode, player)
	if success == true or success == nil then
		minetest.remove_node(pos)
		modlib.table.icall(minetest.registered_on_dignodes, pos, oldnode, player)
	end
end

-- Cancel digging if player changes wield item away from overcharged drill
minetest.register_globalstep(function()
	for player in modlib.minetest.connected_players() do
		if player:get_wielded_item():get_name() ~= itemname_overcharged then
			cancel_digging(player)
		end
	end
end)

minetest.register_on_punchnode(function(pos, _, puncher, pointed_thing)
	if puncher:get_wielded_item():get_name() ~= itemname_overcharged then
		return
	end
	cancel_digging(puncher)
	local above, under = pointed_thing.above, pointed_thing.under
	-- NOTE: This base will not be diagonal in practice.
	local ortho_1, ortho_2 = above:subtract(under):construct_orthonormal_base()
	local dig_actions = {}
	for _, offset in ipairs({ ortho_1, ortho_2, -ortho_1, -ortho_2 }) do
		for _, base_pos in ipairs({ above, under }) do
			local dig_pos = base_pos + offset
			local node = minetest.get_node(dig_pos)
			local drillable = minetest.get_item_group(node.name, "drillable")
			if drillable ~= 0 then
				local time = overcharged_tool_caps.groupcaps.drillable.times[drillable]
				local mid_pos = (dig_pos + base_pos) / 2
				local particlespawner_id = minetest.add_particlespawner({
					amount = math.random(64, 84),
					time = 1.5 * time,
					size = 0, -- randomize sizes
					collisiondetection = false,
					glow = (minetest.registered_nodes[node] or {}).light_source or 0,
					node = node,
					pos = {
						min = mid_pos:subtract(0.5),
						max = mid_pos:add(0.5),
					},
					drag = 0.5,
					jitter = 0.01,
					attract = {
						kind = "point",
						strength = -0.7,
						origin = pos,
					},
					acc = vector.new(0, -9.81 / 2, 0),
					exptime = {
						min = time / 2,
						max = time,
					},
				})
				table.insert(dig_actions, {
					pos = dig_pos,
					job = minetest.after(time, dig_node, dig_pos, puncher),
					particlespawner_id = particlespawner_id,
				})
				break
			end
		end
	end
	digging[puncher:get_player_name()] = dig_actions
end)

itemname_overcharged = register("drill_overcharged", {
	description = "Overcharged Drill",
	tool_capabilities = overcharged_tool_caps,
	after_use = function() end, -- don't wear out
	_deplete_time = 6,
	_on_deplete = function(itemstack, player)
		cancel_digging(player)
		itemstack:set_name(itemname)
		return itemstack
	end,
})

return itemname
