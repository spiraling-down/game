map = {}

local modname = minetest.get_current_modname()

local require = modlib.mod.require

local nodedata = require("nodes")
local nodes, ore_cids = nodedata.nodes, nodedata.ore_cids
local _layers = require("layers")
local deco_groups = require("gen_deco_groups")

local assert, ipairs, pairs = assert, ipairs, pairs

local math_huge, math_min, math_max, math_floor, math_ceil, math_random, math_randomseed =
	math.huge, math.min, math.max, math.floor, math.ceil, math.random, math.randomseed

local vec = vector.new

-- Uses the same v3s16 packing as `minetest.hash_node_position`, but does not need temporary vectors

local function xyz_to_num(x, y, z)
	return ((z + 0x8000) * 0x10000 + (y + 0x8000)) * 0x10000 + x + 0x8000
end

local function num_to_xyz(num)
	local x = num % 0x10000
	num = (num - x) / 0x10000
	local y = num % 0x10000
	num = (num - y) / 0x10000
	local z = num
	return x - 0x8000, y - 0x8000, z - 0x8000
end

for _ = 1, 1e6 do
	local x = math.random(-0x8000, 0x7FFF)
	local y = math.random(-0x8000, 0x7FFF)
	local z = math.random(-0x8000, 0x7FFF)
	local x2, y2, z2 = num_to_xyz(xyz_to_num(x, y, z))
	assert(x == x2 and y == y2 and z == z2)
end

local num_zstride, num_ystride = 0x100000000, 0x10000
local num_neighbor_offsets = { 1, -1, num_ystride, -num_ystride, num_zstride, -num_zstride }

local c_air = minetest.CONTENT_AIR

local variant_cids_by_nodename = modlib.func.memoize(function(nodename)
	local cids = {}
	for variant = 1, assert(nodes[nodename], nodename)._variants do
		cids[variant] = minetest.get_content_id(("%s:%s_%d"):format(modname, nodename, variant))
	end
	assert(#cids > 0)
	return cids
end)

-- Build list of weighted choices; choices may appear multiple times according to their weight
local nodename_choices_by_group = modlib.func.memoize(function(group)
	local list = {}
	for nodename, count in pairs(assert(deco_groups[group], group)) do
		local _ = variant_cids_by_nodename["deco_" .. nodename] -- initialize cids
		for _ = 1, count do
			table.insert(list, "deco_" .. nodename)
		end
	end
	assert(#list > 0)
	return list
end)

local function preprocess_decos(decogroups)
	local base_node_names = {}
	for i, decogroup in ipairs(decogroups) do
		base_node_names[i] = nodename_choices_by_group[decogroup]
	end
	return base_node_names
end

-- Layer preprocessing for generation
local layers = {}
do
	local transition = 10
	local y = 10
	for i, layer in ipairs(_layers) do
		layers[i] = {
			cids = variant_cids_by_nodename[layer.node],
			deco_floor_groups = preprocess_decos(layer.decorations.floor or {}),
			deco_ceil_groups = preprocess_decos(layer.decorations.ceiling or {}),
			y_transition = y,
			y_top = y - (layer.transition or transition),
			_ = layer,
		}
		y = y - layer.height
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

function map.get_layer(pos)
	create_noises()
	local xz = { x = pos.x, y = pos.z }
	local i = 1
	local layer
	repeat
		layer = layers[i]
		local top = math_floor(layer.y_top + layer.noise:get_2d(xz))
		i = i + 1
	until top < pos.y or i == #layers
	return layer._
end

local tunnel_radius = 2
local min_radii, max_radii = vec(10, 5, 10), vec(20, 8, 20)
local chunk_size = 40 -- TODO this is not optimal due to offsets
local min_caves_per_chunk, max_caves_per_chunk = 2, 4
local min_deco_grp_density, max_deco_grp_density = 5e-3, 2e-2
local min_deco_grp_size, max_deco_grp_size = 1, 9
local min_ore_clusters_per_chunk, max_ore_clusters_per_chunk = 30, 70
local ore_coal_chance = 0.69

local function seed_random(minp)
	-- We can't use hash_node_position for this as the randomseed must fit in an int
	local seed = minp.x * 2 ^ 10 + minp.y * 2 ^ 5 + minp.z
	math_randomseed(seed)
end

-- NOTE: Weak keys to allow for garbage collection
local cave_cache = setmetatable({}, { __mode = "k" })

-- Gets the caves for a chunk with the given minp
--! This changes the current global randomseed
local function get_chunk_features(minp)
	local num = xyz_to_num(minp.x, minp.y, minp.z)
	if cave_cache[num] then
		return cave_cache[num]
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

	local ore_clusters = { coal = {}, iron = {} }
	for _ = 1, math_random(min_ore_clusters_per_chunk, max_ore_clusters_per_chunk) do
		local clusters = ore_clusters[math_random() < ore_coal_chance and "coal" or "iron"]
		local center = minp:combine(maxp, math_random)
		-- Distribution skewed heavily towards lower-tier ores
		local max_tier = math_floor((math_random() ^ 4) * 3 + 1.5)
		local center_num = xyz_to_num(center.x, center.y, center.z)
		clusters[center_num] = max_tier
		local last_layer, candidate_list, candidate_set = { center_num }, {}, {}
		for tier = max_tier, 1, -1 do
			for i = 1, 6 do
				local offset = num_neighbor_offsets[i]
				for j = 1, #last_layer do
					local ore_num = last_layer[j]
					local neighbor_num = ore_num + offset
					if not (clusters[neighbor_num] or candidate_set[neighbor_num]) then
						candidate_list[#candidate_list + 1] = neighbor_num
						candidate_set[neighbor_num] = true
					end
				end
			end
			local layer_size = math_floor((0.5 + 0.5 * math_random()) * #candidate_list + 0.5)
			last_layer = {}
			for i = 1, layer_size do
				local cand_idx = math_random(1, #candidate_list)
				local ore_num = candidate_list[cand_idx]
				last_layer[i] = ore_num
				clusters[ore_num] = tier
				candidate_set[ore_num] = nil
				candidate_list[cand_idx] = candidate_list[#candidate_list]
				candidate_list[#candidate_list] = nil
			end
		end
	end

	local features = { caves = caves, ore_clusters = ore_clusters }
	cave_cache[num] = features
	return features
end

minetest.register_on_generated(function(minp, maxp, blockseed)
	local y_top, y_bottom = maxp.y, minp.y

	if layers[1].y_transition < y_bottom then
		return -- only air
	end

	create_noises()

	-- Read
	local reseed = math_random(2 ^ 31 - 1) -- generate seed for reseeding
	math_randomseed(blockseed) -- seed random for this chunk
	local vmanip = minetest.get_mapgen_object("voxelmanip")
	local emin, emax = vmanip:get_emerged_area()
	local varea = VoxelArea:new({ MinEdge = emin, MaxEdge = emax })
	local ystride, zstride = varea.ystride, varea.zstride
	local data = vmanip:get_data()
	local param2_data = vmanip:get_param2_data()
	assert(#data ~= 0 and #param2_data ~= 0)

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
	do
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
						data[y_index] = cids[math_random(1, #cids)] -- NOTE: random has been seeded
						y_index = y_index + ystride -- y++
					end

					bottom = top + 1
				end
				x_index = x_index + 1
			end
			z_index = z_index + zstride -- z++
		end
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
				local chunk_features = get_chunk_features(cp)
				do
					local caves = chunk_features.caves
					local nearby_caves = {}
					for i = 1, #caves do
						nearby_caves[i] = caves[i]
					end
					-- Loop over neighboring chunks and determine their caves
					for nz = cz - chunk_size, cz + chunk_size, chunk_size do
						for ny = cy - chunk_size, cy + chunk_size, chunk_size do
							for nx = cx - chunk_size, cx + chunk_size, chunk_size do
								if nx + ny + nz ~= 0 then
									local ncaves = get_chunk_features(vec(nx, ny, nz))
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
				do
					local ore_clusters = chunk_features.ore_clusters
					for ore_type, clusters in pairs(ore_clusters) do
						for num, tier_idx in pairs(clusters) do
							local x, y, z = num_to_xyz(num)
							if in_bounds(x, y, z) then
								local idx = varea:index(x, y, z)
								local ore_cids_for_node = ore_cids[ore_type][data[idx]]
								if ore_cids_for_node then
									assert(ore_cids_for_node[tier_idx], tier_idx)
									data[idx] = ore_cids_for_node[tier_idx][math_random(#ore_cids_for_node[tier_idx])]
								end
							end
						end
					end
				end
			end
		end
	end

	-- Determine spots for floor decorations; largely redundant with the layer-iterating loop above,
	-- but Lua has no macros and I don't want to incur function call overhead
	local deco_spots_by_layer = {}
	for layer_idx = min_layer_idx, max_layer_idx do
		deco_spots_by_layer[layer_idx - min_layer_idx + 1] = {
			ceil_list = {},
			ceil_map = {},
			floor_list = {},
			floor_map = {},
			layer = layers[layer_idx],
		}
	end
	do
		local margin = 2 -- keep a distance to other chunks so that we don't get noticeable "lines" at chunk borders
		local z_index = varea:indexp(minp:offset(margin, 0, margin))
		local xz_point = { x = 0, y = 0 }
		for z = minp.z + margin, maxp.z - margin do
			xz_point.y = z
			local x_index = z_index
			for x = minp.x + margin, maxp.x - margin do
				xz_point.x = x
				local y_index = x_index + ystride -- NOTE: offset Y by one
				-- Iterate through layers from lowest to highest
				local bottom = y_bottom + 1 -- Y offset
				for layer_idx = max_layer_idx, min_layer_idx, -1 do
					local layer = layers[layer_idx]
					local deco_spots = deco_spots_by_layer[layer_idx - min_layer_idx + 1]
					local floor_map, floor_list = deco_spots.floor_map, deco_spots.floor_list
					local ceil_map, ceil_list = deco_spots.ceil_map, deco_spots.ceil_list
					local top
					if layer_idx > 1 and layer_idx == min_layer_idx then
						-- The first layer of this block must go to the top unless the layer above it is the implicit air layer
						top = y_top - 1 -- NOTE: -1 as we always check the block above
					else
						-- Randomize transitions between layers using perlin noise
						top = math_min(y_top, math_floor(layer.y_top + layer.noise:get_2d(xz_point)))
					end
					for y = bottom, top do
						local next_y_index = y_index + ystride
						-- NOTE: Require y < top such that there always is one block of margin for neighbor calculations
						if data[next_y_index] == c_air and data[y_index] ~= c_air and y < top then
							local list_i = #floor_list + 1
							floor_map[next_y_index] = list_i
							floor_list[list_i] = next_y_index
						elseif data[next_y_index] ~= c_air and data[y_index] == c_air then
							local list_i = #ceil_list + 1
							ceil_map[y_index] = list_i
							ceil_list[list_i] = y_index
						end
						y_index = next_y_index -- y++
					end

					bottom = top + 1
				end
				x_index = x_index + 1
			end
			z_index = z_index + zstride -- z++
		end
	end

	local function place_decorations(listname, mapname, groupsname)
		for i = 1, #deco_spots_by_layer do
			local deco_spots = deco_spots_by_layer[i]
			local list, map, layer = deco_spots[listname], deco_spots[mapname], deco_spots.layer
			local groups = layer[groupsname]
			if #groups > 0 then
				local n_grps = math_floor(
					(min_deco_grp_density + (max_deco_grp_density - min_deco_grp_density) * math_random()) * #list + 0.5
				)
				for _ = 1, n_grps do
					local nodenames = groups[math_random(#groups)]
					local to_place = -- NOTE: x^2 applied to x in [0, 1) skews the distribution towards smaller sizes
						math_floor(
							min_deco_grp_size + math_random() ^ 2 * (max_deco_grp_size - min_deco_grp_size) + 0.5
						)
					local init_idx = list[math_random(1, #list)]
					if not init_idx then
						break
					end
					local cand_list, cand_set = { init_idx }, { [init_idx] = true }
					while to_place > 0 and #cand_list > 0 do
						-- Pick a candidate
						local cand_idx = math_random(#cand_list)
						local vm_idx = cand_list[cand_idx]
						-- Place decoration
						-- HACK always randomize param2, even though decos with paramtype2 = "none" don't need it
						local cids = variant_cids_by_nodename[nodenames[math_random(#nodenames)]]
						data[vm_idx], param2_data[vm_idx] = cids[math_random(#cids)], math_random(0, 3)
						to_place = to_place - 1
						-- Delete from list & map
						local list_idx = map[vm_idx]
						local moved_vm_idx = list[#list]
						-- Fast deletion using a swap
						list[list_idx] = moved_vm_idx
						list[#list] = nil
						-- Update index
						map[moved_vm_idx] = list_idx
						map[vm_idx] = nil
						-- Remove from pickable candidates; don't remove from the set
						local last_candidate = cand_list[#cand_list]
						cand_list[cand_idx] = last_candidate
						cand_list[#cand_list] = nil
						-- Loop over neighboring decoration candidates
						-- NOTE: We don't have to worry about index wraparounds here
						-- because we have ensured a margin of at least 1 for X, Y, Z
						-- TODO (?) this also considers diagonally adjacent nodes neighboring
						for dxidx = vm_idx - 1, vm_idx + 1 do
							for dxyidx = dxidx - ystride, dxidx + ystride, ystride do
								for dxyzidx = dxyidx - zstride, dxyidx + zstride, zstride do
									if map[dxyzidx] and not cand_set[dxyzidx] then
										cand_list[#cand_list + 1] = dxyzidx
										cand_set[dxyzidx] = true
									end
								end
							end
						end
					end
				end
			end
		end
	end
	place_decorations("floor_list", "floor_map", "deco_floor_groups")
	place_decorations("ceil_list", "ceil_map", "deco_ceil_groups")

	-- Write
	vmanip:set_data(data)
	vmanip:set_param2_data(param2_data)
	vmanip:write_to_map()
	math_randomseed(reseed) -- reseed the random
end)
