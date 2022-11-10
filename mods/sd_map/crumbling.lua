-- Node crumbling

local time = 0.5
local max_random_delay = 0.5

local directions = {
	vector.new(1, 0, 0),
	vector.new(-1, 0, 0),
	vector.new(0, 1, 0),
	vector.new(0, -1, 0),
	vector.new(0, 0, 1),
	vector.new(0, 0, -1),
}

local function crumble(pos)
	pos = pos:round() -- get the center of the node
	local node = minetest.get_node(pos)
	if minetest.get_item_group(node.name, "crumbling") == 0 then
		return -- not a crumbling node - nothing happens
	end
	local glow = minetest.get_item_group(node.name, "glow")
	minetest.add_particlespawner({
		amount = math.random(32, 42),
		time = time,
		size = 0, -- randomize sizes
		collisiondetection = false,
		glow = glow,
		node = node,
		pos = {
			min = pos:subtract(0.5),
			max = pos:add(0.5),
		},
		drag = 0.5,
		jitter = 0.01,
		attract = {
			kind = "point",
			strength = -0.3,
			origin = pos,
		},
		exptime = {
			min = time / 2,
			max = time,
		},
	})
	minetest.after(time + max_random_delay * math.random(), function()
		minetest.remove_node(pos)
		for _, direction in ipairs(directions) do
			crumble(pos + direction)
		end
	end)
end

-- Globalstep to detect players walking over blocks
--! assumes crumbling blocks to be of regular size (1³)
minetest.register_globalstep(function()
	for player in modlib.minetest.connected_players() do
		-- Due to the extents of the collisionbox, a player might stand on up to 4 nodes at the same time
		local collisionbox = player:get_properties().collisionbox
		local min_x, min_y, min_z, max_x, _, max_z = unpack(collisionbox)
		local function corner(x, z)
			local bias = 1e-3 -- small bias to move the points just into the below nodes
			crumble(player:get_pos():offset(x, min_y - bias, z))
		end
		corner(min_x, min_z)
		corner(min_x, max_z)
		corner(max_x, min_z)
		corner(max_x, max_z)
	end
end)
