local assert, ipairs, pairs = assert, ipairs, pairs

local math_huge, math_min, math_max, math_floor, math_ceil, math_random, math_randomseed =
	math.huge, math.min, math.max, math.floor, math.ceil, math.random, math.randomseed

local vec = vector.new

local minetest_hash_node_position = minetest.hash_node_position

local c_air = minetest.CONTENT_AIR

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
			spread = vec(50, 50, 50),
			seed = 42,
			octaves = 5,
			persistence = 0.5,
			lacunarity = 2.0,
		}))
	end
	noises_created = true
end

-- TODO this doesn't take tunnels & caves intersecting the top layer into account
function minetest.get_spawn_level(x, z)
	create_noises()
	local top_layer = layers[1]
	return math_max(top_layer.y_top, math_floor(top_layer.y_top + top_layer.noise:get_2d({ x = x, y = z }))) + 0.5
end

local tunnel_radius = 2
local min_radii, max_radii = vec(10, 5, 10), vec(20, 8, 20)
local chunk_size = 40 -- TODO this is not optimal due to offsets
local min_caves_per_chunk = 2
local max_caves_per_chunk = 4

local function seed_random(minp)
	-- We can't use hash_node_position for this as the randomseed must fit in an int
	local seed = minp.x * 2 ^ 10 + minp.y * 2 ^ 5 + minp.z
	math_randomseed(seed)
end

-- NOTE: Weak keys to allow for garbage collection
local cave_cache = setmetatable({}, { __mode = "k" })

-- Gets the caves for a chunk with the given minp
--! This changes the current global randomseed
local function get_caves(minp)
	local hash = minetest_hash_node_position(minp)
	if cave_cache[hash] then
		return cave_cache[hash]
	end

	seed_random(minp)
	local maxp = minp:add(chunk_size)

	local cnt = math_floor(min_caves_per_chunk + math_random() * (max_caves_per_chunk - min_caves_per_chunk) + 0.5)
	local caves = {}
	for i = 1, cnt do
		caves[i] = {
			center = minp:combine(maxp, math_random),
			radii = min_radii:combine(max_radii, math_random),
		}
	end

	cave_cache[hash] = caves
	return caves
end

minetest.register_on_generated(function(minp, maxp)
	local y_top, y_bottom = maxp.y, minp.y

	if layers[1].y_transition < y_bottom then
		return -- only air
	end

	create_noises()

	-- Read
	local reseed = math_random(2 ^ 31 - 1) -- generate seed for reseeding
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
				for _ = bottom, top do
					-- NOTE: `math.random` is used because it is by far the fastest RNG;
					-- determinism is not needed when randomizing nodes
					data[y_index] = cids[math_random(1, #cids)]
					y_index = y_index + ystride -- y++
				end

				bottom = top + 1
			end
			x_index = x_index + 1
		end
		z_index = z_index + zstride -- z++
	end

	-- NOTE: This could be used to clear spheres but would be less efficient
	local function clear_ellipsoid(center, radii)
		local cx, cy, cz = center.x, center.y, center.z
		local rx, ry, rz = radii.x, radii.y, radii.z
		-- Squared scales for computing a scaled distance
		local sqx, sqy, sqz = 1 / (rx * rx), 1 / (ry * ry), 1 / (rz * rz)
		-- Compute extents of the cuboid fully containing the sphere
		local cuboid_min = center:subtract(radii):floor():combine(minp, math_max)
		local cuboid_max = center:add(radii):ceil():combine(maxp, math_min)

		local z_idx = varea:indexp(cuboid_min)
		for relz = cuboid_min.z - cz, cuboid_max.z - cz do
			local z_dist_sq = relz * relz * sqz
			if z_dist_sq <= 1 then
				local zy_idx = z_idx
				for rely = cuboid_min.y - cy, cuboid_max.y - cy do
					local zy_dist_sq = z_dist_sq + rely * rely * sqy
					if zy_dist_sq <= 1 then
						local zyx_idx = zy_idx
						for relx = cuboid_min.x - cx, cuboid_max.x - cx do
							local zyx_dist_sq = zy_dist_sq + relx * relx * sqx
							if zyx_dist_sq <= 1 then -- distance was scaled such that we may check for the unit sphere
								data[zyx_idx] = c_air -- in ellipsoid?
							end
							zyx_idx = zyx_idx + 1
						end
					end
					zy_idx = zy_idx + ystride
				end
			end
			z_idx = z_idx + zstride
		end
	end

	local mnpx, mnpy, mnpz = minp.x, minp.y, minp.z
	local mxpx, mxpy, mxpz = maxp.x, maxp.y, maxp.z
	local function in_bounds(px, py, pz)
		return px >= mnpx and py >= mnpy and pz >= mnpz and px <= mxpx and py <= mxpy and pz <= mxpz
	end

	local function clear_tunnel(from, to, radius)
		local radius_sq = radius * radius
		local diff = to - from
		local dir = diff:normalize()
		local len = diff:length()
		if len == 0 then
			return false -- no tunnel
		end
		local b1, b2 = dir:construct_orthonormal_base()
		local b1x, b1y, b1z = b1.x, b1.y, b1.z
		local b2x, b2y, b2z = b2.x, b2.y, b2.z

		-- Clamp `from` & `to` to mapblock bounds

		-- TODO deduplicate with the below clamping for `to`
		if not in_bounds(from.x, from.y, from.z) then
			local min_t = math_huge
			for c, d in pairs(dir) do
				d = -d
				if d > 0 then
					min_t = math_min(min_t, (maxp[c] - to[c]) / d)
				elseif d < 0 then
					min_t = math_min(min_t, (minp[c] - to[c]) / d)
				end
			end
			assert(min_t < math_huge)
			if min_t < 0 then
				return false -- still not in bounds => tunnel is out of bounds
			end
			from = to - min_t * dir
		end

		if not in_bounds(to.x, to.y, to.z) then
			local min_len = math_huge
			for c, d in pairs(dir) do
				if d > 0 then
					min_len = math_min(min_len, (maxp[c] - from[c]) / d)
				elseif d < 0 then
					min_len = math_min(min_len, (minp[c] - from[c]) / d)
				end
			end
			assert(min_len < math_huge)
			if min_len < 0 then
				return false -- still not in bounds => tunnel is out of bounds
			end
			len = min_len
		end

		if len < 0.5 then
			return false -- tunnel shorter than one node
		end

		-- NOTE: Small bias of 1e-3 to deal with precision issues
		local step = 0.5 -- TODO increase
		step = len / math_ceil(len / step)
		local fx, fy, fz = from.x, from.y, from.z
		local dx, dy, dz = dir.x, dir.y, dir.z
		for i = 0, len + 1e-3, step do -- walk in the tunnel direction...
			local tscx, tscy, tscz = fx + i * dx, fy + i * dy, fz + i * dz
			-- Iterate over UV coordinates of the tunnel slice
			for u = -radius, radius do
				local upx, upy, upz = tscx + u * b1x, tscy + u * b1y, tscz + u * b1z
				local u_dist_sq = u * u
				for v = -radius, radius do
					local uvpx, uvpy, uvpz = upx + v * b2x, upy + v * b2y, upz + v * b2z
					local uv_dist_sq = u_dist_sq + v * v
					if uv_dist_sq <= radius_sq and in_bounds(uvpx, uvpy, uvpz) then
						data[varea:index(math_floor(uvpx), math_floor(uvpy), math_floor(uvpz))] = c_air
					end
				end
			end
		end

		return true
	end

	-- NOTE: subtract/add one to deal with caves of neighboring chunks, which might extend into our chunk
	-- TODO consider throwing in a few random tunnels
	local minchunkp = minp:divide(chunk_size):floor():subtract(1):multiply(chunk_size)
	local maxchunkp = maxp:divide(chunk_size):ceil():add(1):multiply(chunk_size)
	for cz = minchunkp.z, maxchunkp.z, chunk_size do
		for cy = minchunkp.y, maxchunkp.y, chunk_size do
			for cx = minchunkp.x, maxchunkp.x, chunk_size do
				local cp = vec(cx, cy, cz)
				local caves = get_caves(cp)
				local nearby_caves = {}
				for i = 1, #caves do
					nearby_caves[i] = caves[i]
				end
				-- Loop over neighboring chunks and determine their caves
				for nz = cz - chunk_size, cz + chunk_size, chunk_size do
					for ny = cy - chunk_size, cy + chunk_size, chunk_size do
						for nx = cx - chunk_size, cx + chunk_size, chunk_size do
							if nx + ny + nz ~= 0 then
								local ncaves = get_caves(vec(nx, ny, nz))
								for i = 1, #ncaves do -- append all to nearby caves
									nearby_caves[#nearby_caves + 1] = ncaves[i]
								end
							end
						end
					end
				end
				seed_random(cp)
				for i = 1, #caves do
					clear_ellipsoid(caves[i].center, caves[i].radii)
					local cave_blacklist = { [caves[i]] = true }
					-- Add tunnels to closest caves
					for _ = 1, math_random(2, 4) do
						local min_dist, closest_cave = math_huge, nil
						for j = 1, #nearby_caves do
							if not cave_blacklist[nearby_caves[j]] then
								local dist = nearby_caves[j].center:distance(caves[i].center)
								if dist < min_dist then
									min_dist, closest_cave = dist, nearby_caves[j]
								end
							end
						end
						if not closest_cave then
							break
						end
						clear_tunnel(caves[i].center, closest_cave.center, tunnel_radius)
						cave_blacklist[closest_cave] = true
					end
				end
			end
		end
	end

	-- Write
	vmanip:set_data(data)
	vmanip:write_to_map()
	math_randomseed(reseed) -- reseed the random
end)
