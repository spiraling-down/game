-- Common stuff for mapgen that's needed in both the sync & async env
-- Does not (yet) include some data which is passed in `init.lua` via IPC

local gen_common = {}

function gen_common.create_noise(layer)
	return assert(minetest.get_perlin({
		offset = 0,
		scale = layer.y_transition - layer.y_top,
		spread = vector.new(50, 50, 50),
		seed = 42,
		octaves = 5,
		persistence = 0.5,
		lacunarity = 2.0,
	}))
end

-- HACK Minetest does not allow noise creation at load time it seems
-- lazily creates noises (eagerly is not possible)
local noises_created = false
function gen_common.create_noises(layers)
	if noises_created then
		return
	end
	for _, layer in ipairs(layers) do
		-- Each transition between two layers needs its own noise
		-- TODO fully deal with incorrect assumption that the perlin noise was in the [0, scale) range
		layer.noise = gen_common.create_noise(layer)
	end
	noises_created = true
end

return gen_common
