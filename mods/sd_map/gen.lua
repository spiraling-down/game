local math_min, math_max, math_floor = math.min, math.max, math.floor

local modname = minetest.get_current_modname()

modlib.mod.require("nodes")

local layers = {
	-- Implicit: Air
	{
		y_transition = 20, -- where the transition starts
		y_top = 10, -- where the layer starts
		nodename = "granite_regular_1", -- TODO randomize
	},
	{
		y_transition = 0,
		y_top = -10,
		nodename = "basalt_regular_1",
	},
	{
		y_transition = -20,
		y_top = -30,
		nodename = "basalt_regular_2",
	},
}

for _, layer in ipairs(layers) do
	-- Cache content IDs
	layer.cid = minetest.get_content_id(modname .. ":" .. layer.nodename)
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
				local cid = layer.cid
				local top
				if layer_idx > 1 and layer_idx == min_layer_idx then
					-- The first layer of this block must go to the top unless the layer above it is the implicit air layer
					top = y_top
				else
					-- Randomize transitions between layers using perlin noise
					top = math_min(y_top, math_floor(layer.y_top + layer.noise:get_2d(xz_point)))
				end
				for _ = bottom, top do
					data[y_index] = cid
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
