-- Node-"attached" particlespawners
-- TODO optimize this naive implementation

local timer = 0.5
local range = 42

local particlespawners = {}

local nodenames = {}
for nodename, def in pairs(minetest.registered_nodes) do
	if def._add_particlespawner then
		table.insert(nodenames, nodename)
	end
end

local function get_distance_to_closest_player(pos)
	local min_dist = math.huge
	for player in modlib.minetest.connected_players() do
		min_dist = math.min(min_dist, pos:distance(player:get_pos()))
	end
	return min_dist
end

local function add_particlespawner(pos, node)
	if get_distance_to_closest_player(pos) <= range then
		local poshash = minetest.hash_node_position(pos)
		particlespawners[poshash] = particlespawners[poshash]
			or minetest.registered_nodes[node.name]._add_particlespawner(pos, node)
	end
end

minetest.register_lbm({
	label = "Add node particlespawners",
	name = minetest.get_current_modname() .. ":add_node_particlespawners",
	nodenames = nodenames,
	run_at_every_load = true,
	action = add_particlespawner,
})

minetest.register_abm({
	label = "Add node particlespawners",
	nodenames = nodenames,
	interval = timer,
	chance = 1,
	min_y = -32768,
	max_y = 32767, -- TODO use something around 0 here?
	action = add_particlespawner,
})

-- No minetest.register_ubm :(
modlib.minetest.register_globalstep(timer, function()
	for poshash, id in pairs(particlespawners) do
		local pos = minetest.get_position_from_hash(poshash)
		if (not minetest.get_node_or_nil(pos)) or get_distance_to_closest_player(pos) > range then -- unloaded / out of range?
			minetest.delete_particlespawner(id)
			particlespawners[poshash] = nil
		end
	end
end)

minetest.register_on_dignode(function(pos)
	minetest.chat_send_all("dug!")
	local id = particlespawners[minetest.hash_node_position(pos)]
	if id then
		minetest.delete_particlespawner(id)
	end
end)
