local math_min, math_max, math_floor, math_random = math.min, math.max, math.floor, math.random

local modname = minetest.get_current_modname()

local nodes = modlib.mod.require("nodes")

local layers = {
	-- Implicit: Air
	{
		y_transition = 20, -- where the transition starts
		y_top = 10, -- where the layer starts
		nodename = "granite",
	},
	{
		y_transition = 0,
		y_top = -10,
		nodename = "basalt",
	},
	{
		y_transition = -20,
		y_top = -30,
		nodename = "limestone",
	},
}

for _, layer in ipairs(layers) do
	-- Cache content IDs
	layer.cids = {}
	for variant = 1, nodes[layer.nodename]._ do
		layer.cids[variant] = minetest.get_content_id(("%s:%s_%d"):format(modname, layer.nodename, variant))
	end
end

-- HACK Minetest does not allow noise creation at load time it seems
-- lazily creates noises (ahead-of-time is not possible)
local noises_created = false
local function create_noises()
	if noises_created then
		return
	end
	for _, layer in ipairs(layers) do
		-- Each transition between two layers needs its own noise
		-- TODO fully deal with incorrect assumption that the perlin noise was in the [0, scale) range
		layer.noise = assert(minetest.get_perlin({
			offset = 0,
			scale = layer.y_transition - layer.y_top,
			spread = vector.new(50, 50, 50),
			seed = 42,
			octaves = 5,
			persistence = 0.5,
			lacunarity = 2.0,
		}))
	end
	noises_created = true
end

function minetest.get_spawn_level(x, z)
	create_noises()
	local top_layer = layers[1]
	return math_max(top_layer.y_top, math_floor(top_layer.y_top + top_layer.noise:get_2d({ x = x, y = z }))) + 0.5
end

-- One cave per "chunk" (which has nothing to do with mapblock size)
local chunk_size = 40
local cave_dimensions = vector.new(10, 3, 10)
local get_minp_from_pos = function(pos)
	return vector.floor(pos / chunk_size) * chunk_size
end

local vector_componentwise_divide = function(v1, v2)
	return vector.new(v1.x / v2.x, v1.y / v2.y, v1.z / v2.z)
end

local get_nearest_cave = function(pos)
	local minp = get_minp_from_pos(pos)
	--Poor Man's Hashing Function
	math.randomseed(minp.x + minp.y + minp.z)
	local cave_pos = vector.new(
		math.random(minp.x + cave_dimensions.x, minp.x + chunk_size - cave_dimensions.x),
		math.random(minp.y + cave_dimensions.y, minp.y + chunk_size - cave_dimensions.y),
		math.random(minp.z + cave_dimensions.z, minp.z + chunk_size - cave_dimensions.z)
	)
	return cave_pos
end

local get_distance_to_nearest_cave = function(pos)
	return vector.length(vector_componentwise_divide(get_nearest_cave(pos) - pos, vector.normalize(cave_dimensions)), 0)
end

local tunnel_radius = 2
local get_distance_from_tunnel = function(pos, tunneldir, tunnelstart)
	local offset = pos - tunnelstart
	if vector.dot(tunneldir, offset) < 0 then
		return tunnel_radius + 1000 --if you are behind the start of the tunnel, don't add a tunnel
	else
		return vector.dot(vector.normalize(vector.cross(vector.cross(tunneldir, offset), tunneldir)), offset)
	end
end

minetest.register_on_generated(function(minp, maxp)
	local y_top, y_bottom = maxp.y, minp.y

	if layers[1].y_transition < y_bottom then
		return -- only air
	end

	create_noises()

	-- Read
	local vmanip = minetest.get_mapgen_object("voxelmanip")
	local emin, emax = vmanip:get_emerged_area()
	local varea = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local ystride, zstride = varea.ystride, varea.zstride
	local data = vmanip:get_data()
	assert(#data ~= 0)

	-- Determine the slice of layers applying to this mapblock using two linear searches:

	-- Find the first layer; it is guaranteed that there is at least one layer
	local min_layer_idx = 1
	while min_layer_idx < #layers and layers[min_layer_idx + 1].y_transition >= y_top do
		min_layer_idx = min_layer_idx + 1
	end

	-- Find the last layer
	local max_layer_idx = min_layer_idx
	while max_layer_idx < #layers and layers[max_layer_idx + 1].y_transition >= y_bottom do
		max_layer_idx = max_layer_idx + 1
	end

	-- Generate map: Loop over nodes in Z-X-Y order;
	-- this is not optimal for cache locality (Z-Y-X would be optimal),
	-- but it is required to minimize expensive perlin noise calls
	local z_index = varea:indexp(minp)
	local xz_point = { x = 0, y = 0 }
	for z = minp.z, maxp.z do
		xz_point.y = z
		local x_index = z_index
		for x = minp.x, maxp.x do
			xz_point.x = x
			local y_index = x_index
			-- Iterate through layers from lowest to highest
			local bottom = y_bottom
			for layer_idx = max_layer_idx, min_layer_idx, -1 do
				local layer = layers[layer_idx]
				local cids = layer.cids
				local top
				if layer_idx > 1 and layer_idx == min_layer_idx then
					-- The first layer of this block must go to the top unless the layer above it is the implicit air layer
					top = y_top
				else
					-- Randomize transitions between layers using perlin noise
					top = math_min(y_top, math_floor(layer.y_top + layer.noise:get_2d(xz_point)))
				end
				for y = bottom, top do
					-- NOTE: `math.random` is used because it is by far the fastest RNG;
					-- determinism is not needed when randomizing nodes
					data[y_index] = cids[math_random(1, #cids)]

					local pos = vector.new(x, y, z)
					--Create caves
					if get_distance_to_nearest_cave(pos) < vector.length(cave_dimensions) then
						data[y_index] = minetest.CONTENT_AIR
					end

					--Create tunnels between a couple nearby caves
					local current_cave = get_nearest_cave(pos)
					--Add/subtract a chunk size to find another cave.
					local nearby_cave1 = get_nearest_cave(vector.add(pos, vector.new(chunk_size, 0, chunk_size)))
					local nearby_cave2 = get_nearest_cave(vector.subtract(pos, vector.new(chunk_size, 0, chunk_size)))
					local nearby_cave3 = get_nearest_cave(vector.add(pos, vector.new(chunk_size, 0, -chunk_size)))
					local nearby_cave4 = get_nearest_cave(vector.subtract(pos, vector.new(chunk_size, 0, -chunk_size)))

					local dist_tunnel1 = get_distance_from_tunnel(pos, nearby_cave1 - current_cave, current_cave)
					if dist_tunnel1 < tunnel_radius then
						data[y_index] = minetest.CONTENT_AIR
					end
					local dist_tunnel2 = get_distance_from_tunnel(pos, nearby_cave2 - current_cave, current_cave)
					if dist_tunnel2 < tunnel_radius then
						data[y_index] = minetest.CONTENT_AIR
					end
					local dist_tunnel3 = get_distance_from_tunnel(pos, nearby_cave3 - current_cave, current_cave)
					if dist_tunnel3 < tunnel_radius then
						data[y_index] = minetest.CONTENT_AIR
					end
					local dist_tunnel4 = get_distance_from_tunnel(pos, nearby_cave4 - current_cave, current_cave)
					if dist_tunnel4 < tunnel_radius then
						data[y_index] = minetest.CONTENT_AIR
					end

					y_index = y_index + ystride -- y++
				end

				bottom = top + 1
			end
			x_index = x_index + 1
		end
		z_index = z_index + zstride
	end

	-- Write
	vmanip:set_data(data)
	vmanip:write_to_map()
end)
