local require = modlib.mod.require

local nodedata = require("nodes")
local _layers = require("layers")
local deco_groups = require("gen_deco_groups")

minetest.register_craftitem("sd_map:stuff", {
	_ = {
		nodedata = nodedata,
		layers = _layers,
		deco_groups = deco_groups,
	}
})

minetest.register_mapgen_dofile(modlib.mod.get_resource"gen.lua")

-- HACK HGAX!

map = {}

-- Layer preprocessing for generation
local layers = {}
do
	local transition = 10
	local y = 10
	for i, layer in ipairs(_layers) do
		layers[i] = {
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
			spread = vector.new(50, 50, 50),
			seed = 42,
			octaves = 5,
			persistence = 0.5,
			lacunarity = 2.0,
		}))
	end
	noises_created = true
end

function map.get_layer(pos)
	create_noises()
	local xz = { x = pos.x, y = pos.z }
	local i = 1
	local layer
	repeat
		layer = layers[i]
		local top = math.floor(layer.y_top + layer.noise:get_2d(xz))
		i = i + 1
	until top < pos.y or i == #layers
	return layer._
end

-- TODO this doesn't take tunnels & caves intersecting the top layer into account
function minetest.get_spawn_level(x, z)
	create_noises()
	local top_layer = layers[1]
	return math.max(top_layer.y_top, math.floor(top_layer.y_top + top_layer.noise:get_2d({ x = x, y = z }))) + 0.5
end
